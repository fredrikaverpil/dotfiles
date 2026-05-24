import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

type BraveSearchResult = {
  title?: string;
  url?: string;
  description?: string;
  profile?: { name?: string };
  age?: string;
  page_age?: string;
};

type BraveSearchResponse = {
  web?: {
    results?: BraveSearchResult[];
  };
};

type ExaMcpResponse = {
  result?: {
    content?: Array<{ type?: string; text?: string }>;
    isError?: boolean;
  };
  error?: { code?: number; message?: string };
};

type SearchParams = {
  query: string;
  count?: number;
  country?: string;
  searchLang?: string;
  freshness?: string;
};

type FetchParams = {
  url: string;
  maxChars?: number;
};

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
}

function toSearchResult(result: BraveSearchResult, index: number): string {
  const title = result.title?.trim() || "Untitled";
  const url = result.url?.trim() || "No URL";
  const description = result.description?.trim();
  const source = result.profile?.name?.trim();
  const age = result.age ?? result.page_age;
  const metadata = [source, age].filter(Boolean).join(" · ");

  return [
    `${index + 1}. ${title}`,
    url,
    metadata ? `Source: ${metadata}` : undefined,
    description,
  ]
    .filter(Boolean)
    .join("\n");
}

function buildExaQuery(params: SearchParams): string {
  const parts = [params.query];

  if (params.freshness) {
    parts.push(`freshness: ${params.freshness}`);
  }

  if (params.country) {
    parts.push(`country: ${params.country}`);
  }

  if (params.searchLang) {
    parts.push(`language: ${params.searchLang}`);
  }

  return parts.join(" ");
}

function decodeHtmlEntities(text: string): string {
  return text
    .replaceAll("&nbsp;", " ")
    .replaceAll("&amp;", "&")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">")
    .replaceAll("&quot;", '"')
    .replaceAll("&#39;", "'");
}

function htmlToText(html: string): string {
  return decodeHtmlEntities(
    html
      .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
      .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
      .replace(/<noscript\b[^>]*>[\s\S]*?<\/noscript>/gi, " ")
      .replace(/<[^>]+>/g, " ")
      .replace(/\s+/g, " ")
      .trim(),
  );
}

async function responseError(response: Response): Promise<string> {
  const body = await response.text().catch(() => "");
  const suffix = body ? `\n\n${body.slice(0, 2_000)}` : "";

  return `${response.status} ${response.statusText}${suffix}`;
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function parseExaMcpResponse(body: string): ExaMcpResponse | undefined {
  const dataLines = body.split("\n").filter((line) => line.startsWith("data:"));

  for (const line of dataLines) {
    const payload = line.slice(5).trim();

    if (!payload) {
      continue;
    }

    try {
      const parsed = JSON.parse(payload) as ExaMcpResponse;

      if (parsed.result || parsed.error) {
        return parsed;
      }
    } catch {
      // Ignore non-JSON SSE messages.
    }
  }

  try {
    const parsed = JSON.parse(body) as ExaMcpResponse;

    if (parsed.result || parsed.error) {
      return parsed;
    }
  } catch {
    // Ignore non-JSON responses.
  }

  return undefined;
}

function exaMcpText(parsed: ExaMcpResponse): string {
  if (parsed.error) {
    const code =
      typeof parsed.error.code === "number" ? ` ${parsed.error.code}` : "";
    const message = parsed.error.message || "Unknown error";

    throw new Error(`Exa MCP error${code}: ${message}`);
  }

  if (parsed.result?.isError) {
    const message = parsed.result.content
      ?.find((item) => item.type === "text" && typeof item.text === "string")
      ?.text?.trim();

    throw new Error(message || "Exa MCP returned an error");
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
    throw new Error("Exa MCP returned empty content");
  }

  return text;
}

async function searchWithExaMcp(params: SearchParams, signal?: AbortSignal) {
  const response = await fetch("https://mcp.exa.ai/mcp", {
    method: "POST",
    headers: {
      Accept: "application/json, text/event-stream",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method: "tools/call",
      params: {
        name: "web_search_exa",
        arguments: {
          query: buildExaQuery(params),
          numResults: clamp(Math.floor(params.count ?? 5), 1, 20),
          livecrawl: "fallback",
          type: "auto",
          contextMaxCharacters: 3_000,
        },
      },
    }),
    signal,
  });

  if (!response.ok) {
    throw new Error(await responseError(response));
  }

  const parsed = parseExaMcpResponse(await response.text());

  if (!parsed) {
    throw new Error("Exa MCP returned an empty response");
  }

  return exaMcpText(parsed);
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web using Brave Search when BRAVE_SEARCH_API_KEY is set, otherwise fall back to zero-config Exa MCP search.",
    promptSnippet:
      "Search the web using Brave Search or zero-config Exa MCP for current or external information",
    promptGuidelines: [
      "Use web_search when the user asks for current, recent, external, or web-based information.",
      "After web_search, use web_fetch on promising result URLs when snippets are insufficient or citations need verification.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query." }),
      count: Type.Optional(
        Type.Number({
          description:
            "Number of search results to return, from 1 to 20. Defaults to 5.",
          minimum: 1,
          maximum: 20,
        }),
      ),
      country: Type.Optional(
        Type.String({
          description:
            "Optional Brave country code, for example US, SE, or GB.",
        }),
      ),
      searchLang: Type.Optional(
        Type.String({
          description:
            "Optional Brave search language code, for example en or sv.",
        }),
      ),
      freshness: Type.Optional(
        Type.String({
          description:
            "Optional Brave freshness filter, for example pd, pw, pm, py, or a date range.",
        }),
      ),
    }),
    async execute(_toolCallId, params: SearchParams, signal) {
      const apiKey = process.env.BRAVE_SEARCH_API_KEY;

      if (!apiKey) {
        try {
          const text = await searchWithExaMcp(params, signal);

          return {
            content: [{ type: "text" as const, text }],
            details: {
              provider: "exa-mcp",
              query: params.query,
            },
          };
        } catch (error) {
          return {
            isError: true,
            content: [
              {
                type: "text" as const,
                text: `Exa MCP search failed: ${errorMessage(error)}`,
              },
            ],
          };
        }
      }

      const url = new URL("https://api.search.brave.com/res/v1/web/search");
      url.searchParams.set("q", params.query);
      url.searchParams.set(
        "count",
        String(clamp(Math.floor(params.count ?? 5), 1, 20)),
      );
      url.searchParams.set("text_decorations", "false");
      url.searchParams.set("result_filter", "web");

      if (params.country) url.searchParams.set("country", params.country);
      if (params.searchLang)
        url.searchParams.set("search_lang", params.searchLang);
      if (params.freshness) url.searchParams.set("freshness", params.freshness);

      let response: Response;

      try {
        response = await fetch(url, {
          headers: {
            Accept: "application/json",
            "X-Subscription-Token": apiKey,
          },
          signal,
        });
      } catch (error) {
        return {
          isError: true,
          content: [
            {
              type: "text" as const,
              text: `Brave search failed: ${errorMessage(error)}`,
            },
          ],
        };
      }

      if (!response.ok) {
        return {
          isError: true,
          content: [
            {
              type: "text" as const,
              text: `Brave search failed: ${await responseError(response)}`,
            },
          ],
        };
      }

      const data = (await response.json()) as BraveSearchResponse;
      const results = data.web?.results ?? [];
      const text =
        results.length > 0
          ? results.map(toSearchResult).join("\n\n")
          : "No web results found.";

      return {
        content: [{ type: "text" as const, text }],
        details: {
          provider: "brave",
          query: params.query,
          results,
        },
      };
    },
  });

  pi.registerTool({
    name: "web_fetch",
    label: "Web Fetch",
    description: "Fetch a web page by URL and return readable text.",
    promptSnippet:
      "Fetch a web page by URL and return readable text for verification",
    promptGuidelines: [
      "Use web_fetch to inspect source pages found by web_search instead of relying only on search snippets.",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "HTTP or HTTPS URL to fetch." }),
      maxChars: Type.Optional(
        Type.Number({
          description:
            "Maximum characters to return. Defaults to 20000, max 50000.",
          minimum: 1,
          maximum: 50000,
        }),
      ),
    }),
    async execute(_toolCallId, params: FetchParams, signal) {
      let url: URL;

      try {
        url = new URL(params.url);
      } catch {
        return {
          isError: true,
          content: [
            { type: "text" as const, text: `Invalid URL: ${params.url}` },
          ],
        };
      }

      if (url.protocol !== "http:" && url.protocol !== "https:") {
        return {
          isError: true,
          content: [
            {
              type: "text" as const,
              text: `Unsupported URL protocol: ${url.protocol}`,
            },
          ],
        };
      }

      let response: Response;

      try {
        response = await fetch(url, {
          headers: {
            Accept:
              "text/html, text/plain, application/xhtml+xml;q=0.9, */*;q=0.1",
            "User-Agent": "pi-coding-agent-web-fetch/1.0",
          },
          redirect: "follow",
          signal,
        });
      } catch (error) {
        return {
          isError: true,
          content: [
            {
              type: "text" as const,
              text: `Web fetch failed: ${errorMessage(error)}`,
            },
          ],
        };
      }

      if (!response.ok) {
        return {
          isError: true,
          content: [
            {
              type: "text" as const,
              text: `Web fetch failed: ${await responseError(response)}`,
            },
          ],
        };
      }

      const contentType = response.headers.get("content-type") ?? "";
      const raw = await response.text();
      const readable = contentType.includes("html")
        ? htmlToText(raw)
        : raw.replace(/\s+/g, " ").trim();
      const maxChars = clamp(Math.floor(params.maxChars ?? 20_000), 1, 50_000);
      const truncated = readable.length > maxChars;
      const text = truncated
        ? `${readable.slice(0, maxChars)}\n\n[Truncated at ${maxChars} characters]`
        : readable;

      return {
        content: [{ type: "text" as const, text }],
        details: {
          url: response.url,
          contentType,
          characters: readable.length,
          truncated,
        },
      };
    },
  });
}
