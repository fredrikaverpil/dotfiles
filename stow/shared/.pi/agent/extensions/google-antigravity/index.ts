/**
 * Google Antigravity OAuth Provider
 *
 * Use Gemini models with a personal Google account (free Antigravity quota),
 * ported from the opencode plugin "opencode-antigravity-auth"
 * (https://github.com/NoeFabris/opencode-antigravity-auth).
 *
 * Note: Google's older "Gemini CLI" OAuth flow (used by opencode-gemini-auth)
 * was shut down for consumer accounts on 2026-06-18. Antigravity OAuth is the
 * successor flow and is what this extension implements.
 *
 * How it works:
 *  1. /login google-antigravity runs the Antigravity OAuth flow (PKCE +
 *     localhost:51121 callback, with a manual paste fallback) and discovers
 *     the Cloud Code project id via loadCodeAssist, provisioning one with
 *     onboardUser if the account does not have one yet.
 *  2. The model catalog comes from fetchAvailableModels (refreshed by
 *     `pi update --models`), since the account's ids change over time --
 *     gemini-3-pro, for one, is already retired in favour of gemini-3.1-pro.
 *  3. A local reverse proxy on 127.0.0.1 translates between pi's built-in
 *     google-generative-ai adapter and the Cloud Code internal API:
 *       - wraps requests  {project, model, request, userAgent, requestId}
 *       - unwraps SSE     data: {"response": {...}} -> data: {...}
 *       - swaps x-goog-api-key (the OAuth access token) for a Bearer header
 *       - rewrites gemini-3[.x]-pro to its -low/-high tier-suffixed id based
 *         on the thinking level pi put in generationConfig.thinkingConfig
 *         (each model's thinkingLevelMap restricts which levels can get here)
 *
 * Usage:
 *   /login google-antigravity
 *   /model google-antigravity/gemini-3.1-pro
 *
 * Optional env vars:
 *   PI_ANTIGRAVITY_PROJECT_ID / GOOGLE_CLOUD_PROJECT  - force a project id
 */

import { appendFileSync } from "node:fs";
import { createServer, type Server } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type {
  OAuthCredentials,
  OAuthLoginCallbacks,
} from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  type CatalogEntry,
  catalogFromModels,
  type ModelInfo,
  resolveModelId,
  unwrapSseChunk,
} from "./translate.ts";

// =============================================================================
// Constants (from opencode-antigravity-auth src/constants.ts)
// =============================================================================

const CLIENT_ID =
  "1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com";
const CLIENT_SECRET = "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";
const REDIRECT_URI = "http://localhost:51121/oauth-callback";
const CALLBACK_PORT = 51121;
const SCOPES = [
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/userinfo.email",
  "https://www.googleapis.com/auth/userinfo.profile",
  "https://www.googleapis.com/auth/cclog",
  "https://www.googleapis.com/auth/experimentsandconfigs",
];

const ENDPOINT_DAILY = "https://daily-cloudcode-pa.sandbox.googleapis.com";
const ENDPOINT_PROD = "https://cloudcode-pa.googleapis.com";
const ENDPOINT_AUTOPUSH =
  "https://autopush-cloudcode-pa.sandbox.googleapis.com";
/**
 * Request fallback order (mirrors CLIProxy/Vibeproxy: daily first). The daily
 * sandbox tends to get new Antigravity models before prod, which is why it is
 * primary despite being a sandbox; prod catches everything it 404s on. Drop it
 * from this list once prod serves the model ids in `models` below.
 */
const REQUEST_ENDPOINTS = [ENDPOINT_DAILY, ENDPOINT_PROD];
/** loadCodeAssist order (prod resolves managed projects best). */
const LOAD_ENDPOINTS = [ENDPOINT_PROD, ENDPOINT_DAILY, ENDPOINT_AUTOPUSH];

const TOKEN_URL = "https://oauth2.googleapis.com/token";
const AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";

const PLATFORM = process.platform === "win32" ? "WINDOWS" : "MACOS";
/**
 * ClientMetadata.Platform enum, which request bodies are validated against:
 * PLATFORM_UNSPECIFIED | {DARWIN,LINUX}_{AMD64,ARM64} | WINDOWS_AMD64. The
 * looser "MACOS" upstream sends works in the Client-Metadata header but 400s
 * in the body, which silently broke project discovery.
 */
const METADATA_PLATFORM = `${
  { darwin: "DARWIN", win32: "WINDOWS", linux: "LINUX" }[
    process.platform as string
  ] ?? "LINUX"
}_${process.arch === "arm64" && process.platform !== "win32" ? "ARM64" : "AMD64"}`;
const ANTIGRAVITY_HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Antigravity/1.18.3 Chrome/138.0.7204.235 Electron/37.3.1 Safari/537.36",
  "X-Goog-Api-Client": "google-cloud-sdk vscode_cloudshelleditor/0.1",
  "Client-Metadata": `{"ideType":"ANTIGRAVITY","platform":"${PLATFORM}","pluginType":"GEMINI"}`,
};
const TOKEN_HEADERS = { "User-Agent": "google-api-nodejs-client/9.15.1" };

/** Project id resolved at login; env vars take precedence per request. */
let discoveredProjectId = "";

const NO_PROJECT_MESSAGE =
  "No Cloud Code project found for this account. Set PI_ANTIGRAVITY_PROJECT_ID (or GOOGLE_CLOUD_PROJECT) to a project id you own, then run /login google-antigravity again.";

function resolveProjectId(): string {
  return (
    process.env.PI_ANTIGRAVITY_PROJECT_ID ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    discoveredProjectId
  );
}

// =============================================================================
// OAuth helpers
// =============================================================================

async function generatePKCE(): Promise<{
  verifier: string;
  challenge: string;
}> {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  const verifier = btoa(String.fromCharCode(...array))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
  const hash = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(verifier),
  );
  const challenge = btoa(String.fromCharCode(...new Uint8Array(hash)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
  return { verifier, challenge };
}

function buildAuthUrl(challenge: string, state: string): string {
  const url = new URL(AUTH_URL);
  url.searchParams.set("client_id", CLIENT_ID);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("redirect_uri", REDIRECT_URI);
  url.searchParams.set("scope", SCOPES.join(" "));
  url.searchParams.set("code_challenge", challenge);
  url.searchParams.set("code_challenge_method", "S256");
  url.searchParams.set("state", state);
  url.searchParams.set("access_type", "offline");
  url.searchParams.set("prompt", "consent");
  return url.toString();
}

/** Wait for the OAuth redirect on localhost:51121. Rejects if binding fails or on timeout. */
function waitForCallback(
  state: string,
  timeoutMs = 5 * 60 * 1000,
): Promise<string> {
  return new Promise((resolve, reject) => {
    let server: Server | undefined;
    const timer = setTimeout(() => {
      server?.close();
      reject(new Error("Timed out waiting for the browser callback"));
    }, timeoutMs);

    server = createServer((req, res) => {
      const url = new URL(req.url ?? "/", `http://localhost:${CALLBACK_PORT}`);
      if (url.pathname !== "/oauth-callback") {
        res.writeHead(404).end("Not found");
        return;
      }
      const code = url.searchParams.get("code");
      const error = url.searchParams.get("error");
      clearTimeout(timer);
      server?.close();
      if (url.searchParams.get("state") !== state) {
        res.writeHead(400).end("State mismatch. You can close this tab.");
        reject(new Error("OAuth state mismatch"));
        return;
      }
      if (error || !code) {
        res
          .writeHead(400)
          .end(
            `Authentication failed: ${error ?? "missing code"}. You can close this tab.`,
          );
        reject(new Error(error ?? "Missing authorization code"));
        return;
      }
      res
        .writeHead(200, { "Content-Type": "text/html" })
        .end(
          "<html><body><h2>Authentication complete</h2><p>You can close this tab and return to pi.</p></body></html>",
        );
      resolve(code);
    });

    server.once("error", (err) => {
      clearTimeout(timer);
      reject(err);
    });
    // Bind without a host so both IPv4 and IPv6 "localhost" work.
    server.listen(CALLBACK_PORT);
  });
}

function extractCode(pasted: string): string {
  const trimmed = pasted.trim();
  if (trimmed.startsWith("http")) {
    const code = new URL(trimmed).searchParams.get("code");
    if (!code) throw new Error("No authorization code found in the pasted URL");
    return code;
  }
  if (!trimmed) throw new Error("No authorization code provided");
  return trimmed;
}

interface TokenResponse {
  access_token: string;
  refresh_token?: string;
  expires_in: number;
}

async function exchangeCode(
  code: string,
  verifier: string,
): Promise<TokenResponse> {
  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
      Accept: "*/*",
      ...TOKEN_HEADERS,
    },
    body: new URLSearchParams({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      code,
      grant_type: "authorization_code",
      redirect_uri: REDIRECT_URI,
      code_verifier: verifier,
    }),
  });
  if (!response.ok)
    throw new Error(`Token exchange failed: ${await response.text()}`);
  const data = (await response.json()) as TokenResponse;
  if (!data.refresh_token)
    throw new Error(
      "No refresh token in response; try revoking access and logging in again",
    );
  return data;
}

interface CodeAssistPayload {
  cloudaicompanionProject?: string | { id?: string };
  allowedTiers?: { id?: string; isDefault?: boolean }[];
}

function extractProjectId(payload: CodeAssistPayload | undefined): string {
  const project = payload?.cloudaicompanionProject;
  if (typeof project === "string") return project;
  return typeof project?.id === "string" ? project.id : "";
}

async function loadCodeAssist(
  accessToken: string,
): Promise<CodeAssistPayload | undefined> {
  for (const endpoint of LOAD_ENDPOINTS) {
    try {
      const response = await fetch(`${endpoint}/v1internal:loadCodeAssist`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
          // Identify as Antigravity here too: with the google-api-nodejs-client
          // UA, Google reports free-tier as UNSUPPORTED_CLIENT.
          ...ANTIGRAVITY_HEADERS,
        },
        body: JSON.stringify({
          metadata: {
            ideType: "ANTIGRAVITY",
            platform: METADATA_PLATFORM,
            pluginType: "GEMINI",
          },
        }),
        signal: AbortSignal.timeout(10_000),
      });
      const body = await response.text();
      log("loadCodeAssist", { endpoint, status: response.status, body });
      if (!response.ok) continue;
      return JSON.parse(body) as CodeAssistPayload;
    } catch (error) {
      log("loadCodeAssist", { endpoint, error: String(error) });
    }
  }
  return undefined;
}

/**
 * Provision a managed Code Assist project for accounts that do not have one
 * yet (onboardUser is long-running, hence the polling).
 */
async function onboardUser(
  accessToken: string,
  tierId: string,
  attempts = 10,
  delayMs = 5000,
): Promise<string> {
  for (const endpoint of REQUEST_ENDPOINTS) {
    for (let attempt = 0; attempt < attempts; attempt += 1) {
      try {
        const response = await fetch(`${endpoint}/v1internal:onboardUser`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
            ...ANTIGRAVITY_HEADERS,
          },
          body: JSON.stringify({
            tierId,
            metadata: {
              ideType: "ANTIGRAVITY",
              platform: METADATA_PLATFORM,
              pluginType: "GEMINI",
            },
          }),
          signal: AbortSignal.timeout(30_000),
        });
        const body = await response.text();
        log("onboardUser", {
          endpoint,
          tierId,
          attempt,
          status: response.status,
          body,
        });
        if (!response.ok) break; // try the next endpoint
        const payload = JSON.parse(body) as {
          done?: boolean;
          response?: CodeAssistPayload;
        };
        if (payload.done) return extractProjectId(payload.response);
      } catch (error) {
        log("onboardUser", { endpoint, error: String(error) });
        break; // try the next endpoint
      }
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }
  }
  return "";
}

async function fetchProjectId(
  accessToken: string,
  onProgress?: (message: string) => void,
): Promise<string> {
  const payload = await loadCodeAssist(accessToken);
  const projectId = extractProjectId(payload);
  if (projectId) return projectId;
  // No managed project yet: ask Antigravity to provision one on the account's
  // default tier, the way the Antigravity IDE does on first run.
  const tier =
    payload?.allowedTiers?.find((t) => t.isDefault) ??
    payload?.allowedTiers?.[0];
  onProgress?.(
    "Provisioning a Cloud Code project (this can take a minute) ...",
  );
  return onboardUser(accessToken, tier?.id ?? "FREE");
}

// =============================================================================
// OAuth flow (pi integration)
// =============================================================================

async function login(
  callbacks: OAuthLoginCallbacks,
): Promise<OAuthCredentials> {
  const { verifier, challenge } = await generatePKCE();
  const state = crypto.randomUUID();
  const url = buildAuthUrl(challenge, state);

  const method = await callbacks.onSelect({
    message: "Sign in with Google (Antigravity):",
    options: [
      { id: "local", label: "Browser on this machine (automatic callback)" },
      {
        id: "manual",
        label: "Remote/headless - paste the redirect URL manually",
      },
    ],
  });
  if (!method) throw new Error("Login cancelled");

  let code: string | undefined;
  if (method === "local") {
    try {
      const callback = waitForCallback(state);
      callbacks.onAuth({ url });
      callbacks.onProgress?.(
        "Waiting for the browser callback on localhost:51121 ...",
      );
      code = await callback;
    } catch (error) {
      callbacks.onProgress?.(
        `Automatic callback failed (${error instanceof Error ? error.message : String(error)}); falling back to manual entry.`,
      );
    }
  }
  if (!code) {
    callbacks.onAuth({ url });
    code = extractCode(
      await callbacks.onPrompt({
        message:
          "After authorizing, the browser redirects to localhost:51121 (the page may fail to load). Paste the full redirect URL or just the code:",
      }),
    );
  }

  callbacks.onProgress?.("Exchanging authorization code ...");
  const tokens = await exchangeCode(code, verifier);

  callbacks.onProgress?.("Discovering Cloud Code project ...");
  discoveredProjectId = await fetchProjectId(
    tokens.access_token,
    callbacks.onProgress,
  );
  const projectId = resolveProjectId();
  if (!projectId) throw new Error(NO_PROJECT_MESSAGE);

  // Stash the project id alongside the refresh token (same trick as the
  // opencode plugin) so it survives restarts; getApiKey() recovers it.
  return {
    refresh: `${tokens.refresh_token}|${projectId}`,
    access: tokens.access_token,
    expires: Date.now() + tokens.expires_in * 1000 - 5 * 60 * 1000,
  };
}

async function refreshToken(
  credentials: OAuthCredentials,
): Promise<OAuthCredentials> {
  const [storedRefresh, projectId = ""] = credentials.refresh.split("|");
  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      ...TOKEN_HEADERS,
    },
    body: new URLSearchParams({
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      grant_type: "refresh_token",
      refresh_token: storedRefresh,
    }),
  });
  if (!response.ok)
    throw new Error(`Token refresh failed: ${await response.text()}`);
  const data = (await response.json()) as TokenResponse;
  if (projectId) discoveredProjectId = projectId;
  return {
    refresh: `${data.refresh_token ?? storedRefresh}|${projectId}`,
    access: data.access_token,
    expires: Date.now() + data.expires_in * 1000 - 5 * 60 * 1000,
  };
}

function getApiKey(credentials: OAuthCredentials): string {
  const [, projectId = ""] = credentials.refresh.split("|");
  if (projectId) discoveredProjectId = projectId;
  return credentials.access;
}

// =============================================================================
// Local reverse proxy: Gemini API <-> Cloud Code internal API
// =============================================================================

async function readBody(
  req: import("node:http").IncomingMessage,
): Promise<string> {
  let data = "";
  for await (const chunk of req) data += chunk;
  return data;
}

/** Unwrap Cloud Code SSE frames: data: {"response": {...}} -> data: {...} */
async function pipeUnwrappedSse(
  upstream: ReadableStream<Uint8Array>,
  res: import("node:http").ServerResponse,
): Promise<void> {
  const reader = upstream.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  const flushLines = (final: boolean) => {
    const { out, rest } = unwrapSseChunk(buffer, final);
    buffer = rest;
    if (out) res.write(out);
  };
  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      const chunk = decoder.decode(value, { stream: true });
      log("sse", { chunk });
      buffer += chunk;
      flushLines(false);
    }
    flushLines(true);
  } finally {
    reader.releaseLock();
  }
}

const DEBUG = !!process.env.PI_ANTIGRAVITY_DEBUG;
const DEBUG_LOG = join(tmpdir(), "pi-antigravity-debug.log");

function log(event: string, data: unknown) {
  if (!DEBUG) return;
  try {
    appendFileSync(DEBUG_LOG, `${JSON.stringify({ event, data })}\n`);
  } catch {}
}

function createProxy(): Server {
  return createServer(async (req, res) => {
    try {
      const url = new URL(req.url ?? "/", "http://127.0.0.1");
      const match = url.pathname.match(/\/models\/([^:]+):(\w+)$/);
      const accessToken = req.headers["x-goog-api-key"];
      log("request", {
        url: req.url,
        method: req.method,
        hasKey: typeof accessToken,
      });
      if (req.method !== "POST" || !match) {
        res.writeHead(404, { "Content-Type": "application/json" }).end(
          JSON.stringify({
            error: { code: 404, message: "Not found", status: "NOT_FOUND" },
          }),
        );
        return;
      }
      if (typeof accessToken !== "string" || !accessToken) {
        res.writeHead(401, { "Content-Type": "application/json" }).end(
          JSON.stringify({
            error: {
              code: 401,
              message: "Not logged in. Run /login google-antigravity",
              status: "UNAUTHENTICATED",
            },
          }),
        );
        return;
      }

      const [, model = "", action = ""] = match;
      if (action !== "streamGenerateContent" && action !== "generateContent") {
        res.writeHead(404, { "Content-Type": "application/json" }).end(
          JSON.stringify({
            error: {
              code: 404,
              message: `Unsupported action: ${action}`,
              status: "NOT_FOUND",
            },
          }),
        );
        return;
      }
      const streaming = action === "streamGenerateContent";

      const geminiRequest = JSON.parse(await readBody(req)) as {
        generationConfig?: { thinkingConfig?: { thinkingLevel?: string } };
      };

      let effectiveModel: string;
      try {
        effectiveModel = resolveModelId(
          model,
          geminiRequest.generationConfig?.thinkingConfig?.thinkingLevel,
        );
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        res.writeHead(400, { "Content-Type": "application/json" }).end(
          JSON.stringify({
            error: { code: 400, message, status: "INVALID_ARGUMENT" },
          }),
        );
        return;
      }

      const projectId = resolveProjectId();
      if (!projectId) {
        res.writeHead(400, { "Content-Type": "application/json" }).end(
          JSON.stringify({
            error: {
              code: 400,
              message: NO_PROJECT_MESSAGE,
              status: "FAILED_PRECONDITION",
            },
          }),
        );
        return;
      }

      const wrappedBody = JSON.stringify({
        project: projectId,
        model: effectiveModel,
        request: geminiRequest,
        userAgent: "antigravity",
        requestId: `agent-${crypto.randomUUID()}`,
      });

      let lastStatus = 502;
      let lastError = "All Cloud Code endpoints failed";
      for (const endpoint of REQUEST_ENDPOINTS) {
        let upstream: Response;
        try {
          upstream = await fetch(
            `${endpoint}/v1internal:${action}${streaming ? "?alt=sse" : ""}`,
            {
              method: "POST",
              headers: {
                Authorization: `Bearer ${accessToken}`,
                "Content-Type": "application/json",
                ...(streaming ? { Accept: "text/event-stream" } : {}),
                ...ANTIGRAVITY_HEADERS,
              },
              body: wrappedBody,
            },
          );
        } catch (error) {
          lastStatus = 502;
          lastError = error instanceof Error ? error.message : String(error);
          continue;
        }

        log("upstream", {
          endpoint,
          model: effectiveModel,
          status: upstream.status,
        });
        if (!upstream.ok || !upstream.body) {
          lastStatus = upstream.status;
          lastError = await upstream.text().catch(() => upstream.statusText);
          log("upstreamError", { endpoint, status: lastStatus, lastError });
          continue; // try the next endpoint
        }

        res.writeHead(200, {
          "Content-Type": streaming ? "text/event-stream" : "application/json",
          ...(streaming
            ? { "Cache-Control": "no-cache", Connection: "keep-alive" }
            : {}),
        });
        if (streaming) {
          await pipeUnwrappedSse(upstream.body, res);
          res.end();
        } else {
          const parsed = (await upstream.json()) as { response?: unknown };
          res.end(JSON.stringify(parsed.response ?? parsed));
        }
        return;
      }

      // All endpoints failed - relay the last upstream status so pi's
      // rate-limit / overflow detection sees the real error.
      res.writeHead(lastStatus, { "Content-Type": "application/json" }).end(
        lastError.trimStart().startsWith("{")
          ? lastError
          : JSON.stringify({
              error: {
                code: lastStatus,
                message: lastError,
                status: "UNKNOWN",
              },
            }),
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      log("error", {
        message,
        stack: error instanceof Error ? error.stack : "",
      });
      if (!res.headersSent) {
        res.writeHead(500, { "Content-Type": "application/json" }).end(
          JSON.stringify({
            error: { code: 500, message, status: "INTERNAL" },
          }),
        );
      } else {
        res.end();
      }
    }
  });
}

function listen(server: Server): Promise<number> {
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const address = server.address();
      if (address && typeof address === "object") {
        log("listening", address);
        resolve(address.port);
      } else reject(new Error("Failed to determine proxy port"));
    });
  });
}

// =============================================================================
// Model catalog
// =============================================================================

/** Ask Antigravity which models this account may use. */
async function fetchAvailableModels(
  accessToken: string,
  project: string,
  signal?: AbortSignal,
): Promise<Record<string, ModelInfo>> {
  for (const endpoint of REQUEST_ENDPOINTS) {
    try {
      const response = await fetch(
        `${endpoint}/v1internal:fetchAvailableModels`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
            ...ANTIGRAVITY_HEADERS,
          },
          body: JSON.stringify({ project }),
          signal: signal ?? AbortSignal.timeout(15_000),
        },
      );
      const body = await response.text();
      log("fetchAvailableModels", { endpoint, status: response.status });
      if (!response.ok) continue;
      const { models } = JSON.parse(body) as {
        models?: Record<string, ModelInfo>;
      };
      if (models) return models;
    } catch (error) {
      log("fetchAvailableModels", { endpoint, error: String(error) });
    }
  }
  return {};
}

const free = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 };

// Which pi thinking levels Antigravity accepts; null hides a level from pi's UI
// so it never reaches the wire. Pro takes low/high only (as the model-id
// suffix), Flash takes minimal/low/medium/high as thinkingLevel, and ids with
// the level baked in take none at all.
const THINKING_LEVEL_MAP = {
  pro: {
    off: null,
    minimal: null,
    low: "low",
    medium: null,
    high: "high",
    xhigh: null,
    max: null,
  },
  flash: {
    off: null,
    minimal: "minimal",
    low: "low",
    medium: "medium",
    high: "high",
    xhigh: null,
    max: null,
  },
  none: undefined,
};

function toModel({ id, kind, name, maxTokens }: CatalogEntry) {
  return {
    id,
    name: `${name} (Antigravity)`,
    reasoning: kind !== "none",
    thinkingLevelMap: THINKING_LEVEL_MAP[kind],
    input: ["text", "image"],
    cost: free,
    contextWindow: 1048576,
    maxTokens,
  };
}

/**
 * Catalog used until a refresh runs (`pi update --models`), since the fetch
 * needs credentials the extension factory does not have. Verified live; the
 * rest of the account's ids come from the refresh.
 */
const INITIAL_CATALOG = catalogFromModels({
  "gemini-3.1-pro-low": { maxOutputTokens: 65535 },
  "gemini-3.1-pro-high": { maxOutputTokens: 65535 },
  "gemini-3-flash": { displayName: "Gemini 3 Flash", maxOutputTokens: 65536 },
});

// =============================================================================
// Extension entry point
// =============================================================================

export default function (pi: ExtensionAPI) {
  let catalog = INITIAL_CATALOG;

  const register = (baseUrl: string) =>
    pi.registerProvider("google-antigravity", {
      name: "Google (Antigravity OAuth)",
      baseUrl,
      api: "google-generative-ai",
      models: catalog.map(toModel),
      // Called by `pi update --models`; the factory itself has no credentials.
      async refreshModels(context: {
        credential?: { access?: string; refresh?: string };
        signal?: AbortSignal;
      }) {
        log("refreshModels", { keys: Object.keys(context ?? {}) });
        const access = context?.credential?.access ?? "";
        const project =
          context?.credential?.refresh?.split("|")[1] || resolveProjectId();
        if (access && project) {
          const models = await fetchAvailableModels(
            access,
            project,
            context.signal,
          );
          log("refreshModels", { fetched: Object.keys(models).length });
          if (Object.keys(models).length) catalog = catalogFromModels(models);
        }
        return catalog.map(toModel);
      },
      oauth: {
        name: "Google (Antigravity)",
        login,
        refreshToken,
        getApiKey,
      },
    });

  // Register up front (placeholder URL) so /model and --list-models see the
  // models without binding a socket, then re-register with the live port once a
  // session actually starts. pi applies registrations made after the factory
  // immediately, and no request can happen before session_start.
  register("http://127.0.0.1:0");

  let proxy: Server | undefined;
  pi.on("session_start", async () => {
    if (proxy) return;
    proxy = createProxy();
    register(`http://127.0.0.1:${await listen(proxy)}`);
  });
  pi.on("session_shutdown", async () => {
    proxy?.close();
    proxy = undefined;
  });
}
