/**
 * Pure translation helpers between the Gemini API and the Cloud Code internal
 * API. Kept free of imports so they can be tested with plain `deno test`
 * (index.ts imports types from pi's runtime, which is not resolvable here).
 */

const GEMINI3_PRO_REGEX = /^gemini-3(?:\.\d+)?-pro$/i;

/**
 * Antigravity requires Gemini 3 Pro tier suffixes; Gemini 3 Flash uses the bare
 * model id plus thinkingLevel (which pi already sends). Each pro model's
 * thinkingLevelMap only lets "low" and "high" through, so anything else here is
 * a bug rather than something to silently downgrade. pi's google-generative-ai
 * adapter upper-cases the level on the wire ("HIGH"), hence the fold.
 */
export function resolveModelId(
  model: string,
  thinkingLevel: string | undefined,
): string {
  if (!GEMINI3_PRO_REGEX.test(model)) return model;
  const tier = thinkingLevel?.toLowerCase();
  if (tier !== "low" && tier !== "high") {
    throw new Error(
      `Unsupported thinking level "${thinkingLevel}" for ${model}; expected "low" or "high"`,
    );
  }
  return `${model}-${tier}`;
}

/**
 * How a model id takes its thinking level:
 *  - "pro":   the level is a -low/-high suffix on the model id
 *  - "flash": the level is a thinkingLevel field on the request
 *  - "none":  the level is baked into the id (or unsupported), so pi must not
 *             send one at all
 */
export type ModelKind = "pro" | "flash" | "none";

/** Bare `gemini-3-flash` / `gemini-3.1-flash`, with no baked-in level. */
const BARE_FLASH_REGEX = /^gemini-\d+(?:\.\d+)?-flash$/;

/** The bits of a fetchAvailableModels entry the catalog uses. */
export interface ModelInfo {
  displayName?: string;
  maxOutputTokens?: number;
}

export interface CatalogEntry {
  id: string;
  kind: ModelKind;
  name: string;
  maxTokens: number;
}

/**
 * Turn the raw fetchAvailableModels payload into the catalog pi should show:
 * Gemini only (the account also lists claude and gpt-oss ids the proxy cannot
 * translate, plus internal tab_ and chat_ entries), with the tier-suffixed pro
 * ids collapsed into the base id resolveModelId re-expands.
 *
 * Google's ids are internal placeholders -- gemini-3.5-flash-low reports itself
 * as "Gemini 3.5 Flash (Medium)" -- so displayName wins where it exists. Ids
 * without one (the -tiered aliases) are not user-facing in Antigravity either.
 */
export function catalogFromModels(
  models: Record<string, ModelInfo>,
): CatalogEntry[] {
  const entries = new Map<string, CatalogEntry>();
  for (const [id, info] of Object.entries(models)) {
    if (!id.startsWith("gemini-")) continue;
    const pro = id.match(/^(.*-pro)-(?:low|high)$/);
    const baseId = pro ? pro[1] : id;
    const kind: ModelKind = pro
      ? "pro"
      : BARE_FLASH_REGEX.test(id)
        ? "flash"
        : "none";
    entries.set(baseId, {
      id: baseId,
      kind,
      // Pro's display names are per tier ("Gemini 3.1 Pro (Low)"), which says
      // nothing useful once both tiers are one entry.
      name: (pro ? undefined : info.displayName) ?? baseId,
      maxTokens: info.maxOutputTokens ?? 65536,
    });
  }
  return [...entries.values()].sort((a, b) => a.id.localeCompare(b.id));
}

/**
 * Unwrap the complete SSE lines in `buffer`: data: {"response": {...}} becomes
 * data: {...}. Returns the text to forward plus the trailing partial line, which
 * the caller feeds back in with the next chunk (`final` flushes it).
 */
export function unwrapSseChunk(
  buffer: string,
  final: boolean,
): { out: string; rest: string } {
  const lines = buffer.split("\n");
  const rest = final ? "" : (lines.pop() ?? "");
  let out = "";
  for (const line of lines) {
    const trimmed = line.trimEnd();
    if (trimmed.startsWith("data:")) {
      try {
        const parsed = JSON.parse(trimmed.slice(5).trim()) as {
          response?: unknown;
        };
        out += `data: ${JSON.stringify(parsed.response ?? parsed)}\n\n`;
        continue;
      } catch {
        // not JSON - pass through
      }
    }
    out += `${line}\n`;
  }
  return { out, rest };
}
