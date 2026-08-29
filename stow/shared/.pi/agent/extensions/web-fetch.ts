import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

type FetchParams = {
  url: string;
  maxChars?: number;
};

function clamp(value: number, min: number, max: number): number {
  return Math.min(Math.max(value, min), max);
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

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

async function responseError(response: Response): Promise<string> {
  const body = await response.text().catch(() => "");
  const suffix = body ? `\n\n${body.slice(0, 2_000)}` : "";

  return `${response.status} ${response.statusText}${suffix}`;
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "web_fetch",
    label: "Web Fetch",
    description: "Fetch a web page by URL and return readable text.",
    promptSnippet:
      "Fetch a web page by URL and return readable text for verification",
    promptGuidelines: [
      "Use web_fetch to inspect source pages found by websearch instead of relying only on search snippets.",
    ],
    parameters: Type.Object({
      url: Type.String({ description: "HTTP or HTTPS URL to fetch." }),
      maxChars: Type.Optional(
        Type.Number({
          description:
            "Maximum characters to return. Defaults to 20000, max 50000.",
          minimum: 1,
          maximum: 50_000,
        }),
      ),
    }),
    async execute(_toolCallId, params: FetchParams, signal) {
      let url: URL;

      try {
        url = new URL(params.url);
      } catch {
        throw new Error(`Invalid URL: ${params.url}`);
      }

      if (url.protocol !== "http:" && url.protocol !== "https:") {
        throw new Error(`Unsupported URL protocol: ${url.protocol}`);
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
        throw new Error(`Web fetch failed: ${errorMessage(error)}`);
      }

      if (!response.ok) {
        throw new Error(`Web fetch failed: ${await responseError(response)}`);
      }

      const contentType = response.headers.get("content-type") ?? "";
      const raw = await response.text();
      const readable = contentType.includes("html")
        ? htmlToText(raw)
        : raw.replace(/\s+/g, " ").trim();
      const maxChars = clamp(Math.floor(params.maxChars ?? 20_000), 1, 50_000);
      const truncated = readable.length > maxChars;
      const text = truncated
        ? `${
          readable.slice(0, maxChars)
        }\n\n[Truncated at ${maxChars} characters]`
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
