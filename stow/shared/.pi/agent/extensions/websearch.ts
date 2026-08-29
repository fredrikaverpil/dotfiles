import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  type ExtensionAPI,
  formatSize,
  truncateHead,
} from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { createHash } from "node:crypto";
import { Type } from "typebox";

type WebSearchProvider = "exa" | "parallel";

type McpResponse = {
  result?: {
    content?: Array<{ type?: string; text?: string }>;
    isError?: boolean;
  };
  error?: { code?: number; message?: string };
};

type SearchParams = {
  query: string;
  numResults?: number;
  livecrawl?: "fallback" | "preferred";
  type?: "auto" | "fast" | "deep";
  contextMaxCharacters?: number;
};

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

async function responseError(response: Response): Promise<string> {
  const body = await response.text().catch(() => "");
  const suffix = body ? `\n\n${body.slice(0, 2_000)}` : "";

  return `${response.status} ${response.statusText}${suffix}`;
}

function parseMcpResponse(body: string): McpResponse | undefined {
  for (const line of body.split("\n")) {
    if (!line.startsWith("data:")) {
      continue;
    }

    const payload = line.slice(5).trim();

    if (!payload) {
      continue;
    }

    try {
      const parsed = JSON.parse(payload) as McpResponse;

      if (parsed.result || parsed.error) {
        return parsed;
      }
    } catch {
      // Ignore non-JSON server-sent events.
    }
  }

  try {
    const parsed = JSON.parse(body) as McpResponse;

    if (parsed.result || parsed.error) {
      return parsed;
    }
  } catch {
    // Ignore non-JSON responses.
  }

  return undefined;
}

function responseText(
  provider: WebSearchProvider,
  parsed: McpResponse,
): string {
  if (parsed.error) {
    const code = typeof parsed.error.code === "number"
      ? ` ${parsed.error.code}`
      : "";
    const message = parsed.error.message || "Unknown error";

    throw new Error(`${provider} MCP error${code}: ${message}`);
  }

  if (parsed.result?.isError) {
    const message = parsed.result.content
      ?.find((item) => item.type === "text" && typeof item.text === "string")
      ?.text?.trim();

    throw new Error(message || `${provider} MCP returned an error`);
  }

  const text = parsed.result?.content
    ?.find(
      (item) =>
        item.type === "text" &&
        typeof item.text === "string" &&
        item.text.trim().length > 0,
    )
    ?.text?.trim();

  if (!text) {
    throw new Error(`${provider} MCP returned empty content`);
  }

  return text;
}

function truncateOutput(output: string): string {
  const truncation = truncateHead(output, {
    maxBytes: DEFAULT_MAX_BYTES,
    maxLines: DEFAULT_MAX_LINES,
  });

  if (!truncation.truncated) {
    return truncation.content;
  }

  return [
    truncation.content,
    "",
    `[Output truncated: ${truncation.outputLines} of ` +
    `${truncation.totalLines} lines (${formatSize(truncation.outputBytes)} ` +
    `of ${formatSize(truncation.totalBytes)}).]`,
  ].join("\n");
}

function providerFromEnvironment(): WebSearchProvider | undefined {
  const provider = process.env.PI_WEBSEARCH_PROVIDER;

  return provider === "exa" || provider === "parallel" ? provider : undefined;
}

function selectProvider(sessionId: string): WebSearchProvider {
  const provider = providerFromEnvironment();

  if (provider) {
    return provider;
  }

  const hash = createHash("sha256").update(sessionId).digest("hex");

  return Number.parseInt(hash.slice(0, 8), 16) % 2 === 0 ? "exa" : "parallel";
}

async function callMcp(
  provider: WebSearchProvider,
  url: string,
  tool: string,
  args: Record<string, unknown>,
  headers: Record<string, string>,
  signal?: AbortSignal,
): Promise<string> {
  const response = await fetch(url, {
    method: "POST",
    headers: {
      Accept: "application/json, text/event-stream",
      "Content-Type": "application/json",
      ...headers,
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "tools/call",
      params: { name: tool, arguments: args },
    }),
    signal,
  });

  if (!response.ok) {
    throw new Error(await responseError(response));
  }

  const parsed = parseMcpResponse(await response.text());

  if (!parsed) {
    throw new Error(`${provider} MCP returned an empty response`);
  }

  return responseText(provider, parsed);
}

async function searchWithExa(
  params: SearchParams,
  signal?: AbortSignal,
): Promise<string> {
  const url = new URL("https://mcp.exa.ai/mcp");
  const apiKey = process.env.EXA_API_KEY;

  if (apiKey) {
    url.searchParams.set("exaApiKey", apiKey);
  }

  return callMcp(
    "exa",
    url.toString(),
    "web_search_exa",
    {
      query: params.query,
      type: params.type ?? "auto",
      numResults: clamp(Math.floor(params.numResults ?? 8), 1, 20),
      livecrawl: params.livecrawl ?? "fallback",
      contextMaxCharacters: params.contextMaxCharacters,
    },
    {},
    signal,
  );
}

async function searchWithParallel(
  params: SearchParams,
  sessionId: string,
  modelName: string | undefined,
  signal?: AbortSignal,
): Promise<string> {
  const apiKey = process.env.PARALLEL_API_KEY;

  return callMcp(
    "parallel",
    "https://search.parallel.ai/mcp",
    "web_search",
    {
      objective: params.query,
      search_queries: [params.query],
      session_id: sessionId,
      model_name: modelName,
    },
    {
      "User-Agent": "pi-coding-agent-websearch/1.0",
      ...(apiKey ? { Authorization: `Bearer ${apiKey}` } : {}),
    },
    signal,
  );
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "websearch",
    label: "Web Search",
    description:
      "Search the web for current information using the session's Exa or Parallel provider.",
    promptSnippet:
      "Search the web through the session's Exa or Parallel provider for current information",
    promptGuidelines: [
      "Use websearch when the user requests current, recent, external, or web-based information.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Web search query." }),
      numResults: Type.Optional(
        Type.Number({
          description:
            "Number of results to return. Defaults to 8; maximum 20.",
          minimum: 1,
          maximum: 20,
        }),
      ),
      livecrawl: Type.Optional(
        StringEnum(["fallback", "preferred"] as const),
      ),
      type: Type.Optional(StringEnum(["auto", "fast", "deep"] as const)),
      contextMaxCharacters: Type.Optional(
        Type.Number({
          description:
            "Maximum result-context characters. Defaults to the provider's default; maximum 50000.",
          minimum: 1,
          maximum: 50_000,
        }),
      ),
    }),
    async execute(_toolCallId, params: SearchParams, signal, _onUpdate, ctx) {
      const sessionId = ctx.sessionManager.getSessionId();
      const provider = selectProvider(sessionId);

      try {
        const text = provider === "exa"
          ? await searchWithExa(params, signal)
          : await searchWithParallel(params, sessionId, ctx.model?.id, signal);

        return {
          content: [{ type: "text" as const, text: truncateOutput(text) }],
          details: { provider, query: params.query },
        };
      } catch (error) {
        throw new Error(
          `Unable to search with ${provider}: ${errorMessage(error)}`,
        );
      }
    },
  });
}
