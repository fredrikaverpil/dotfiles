import { deepStrictEqual, throws } from "node:assert/strict";
import {
  catalogFromModels,
  resolveModelId,
  unwrapSseChunk,
} from "./translate.ts";

Deno.test("catalogFromModels", () => {
  // Arrange: a slice of what fetchAvailableModels actually returns.
  const models = {
    "gemini-3.1-pro-high": {
      displayName: "Gemini 3.1 Pro (High)",
      maxOutputTokens: 65535,
    },
    "gemini-3.1-pro-low": {
      displayName: "Gemini 3.1 Pro (Low)",
      maxOutputTokens: 65535,
    },
    "gemini-3-flash": { displayName: "Gemini 3 Flash", maxOutputTokens: 65536 },
    "gemini-3.6-flash-medium": {
      displayName: "Gemini 3.6 Flash (Medium)",
      maxOutputTokens: 65536,
    },
    "gemini-3.6-flash-tiered": { maxOutputTokens: 65536 },
    "claude-sonnet-4-6": { displayName: "Claude Sonnet 4.6" },
    tab_flash_lite_preview: {},
  };
  const want = [
    {
      id: "gemini-3-flash",
      kind: "flash",
      name: "Gemini 3 Flash",
      maxTokens: 65536,
    },
    {
      id: "gemini-3.1-pro",
      kind: "pro",
      name: "gemini-3.1-pro",
      maxTokens: 65535,
    },
    {
      id: "gemini-3.6-flash-medium",
      kind: "none",
      name: "Gemini 3.6 Flash (Medium)",
      maxTokens: 65536,
    },
    {
      id: "gemini-3.6-flash-tiered",
      kind: "none",
      name: "gemini-3.6-flash-tiered",
      maxTokens: 65536,
    },
  ];

  // Act
  const got = catalogFromModels(models);

  // Assert
  deepStrictEqual(got, want);
});

Deno.test("resolveModelId", () => {
  // Arrange
  const cases = [
    { model: "gemini-3-pro", level: "high", want: "gemini-3-pro-high" },
    // pi's adapter upper-cases the level on the wire.
    { model: "gemini-3-pro", level: "HIGH", want: "gemini-3-pro-high" },
    { model: "gemini-3.7-pro", level: "low", want: "gemini-3.7-pro-low" },
    { model: "gemini-3-flash", level: "medium", want: "gemini-3-flash" },
    { model: "gemini-3.5-flash", level: undefined, want: "gemini-3.5-flash" },
  ];

  // Act
  const got = cases.map(({ model, level }) => ({
    model,
    level,
    want: resolveModelId(model, level),
  }));

  // Assert
  deepStrictEqual(got, cases);
  throws(
    () => resolveModelId("gemini-3-pro", "medium"),
    /Unsupported thinking level "medium"/,
  );
});

Deno.test("unwrapSseChunk", () => {
  // Arrange
  const cases = [
    {
      buffer: 'data: {"response": {"text": "hi"}}\n',
      final: false,
      want: { out: 'data: {"text":"hi"}\n\n', rest: "" },
    },
    {
      buffer: 'data: {"text": "hi"}\n',
      final: false,
      want: { out: 'data: {"text":"hi"}\n\n', rest: "" },
    },
    {
      buffer: 'data: {"response": {"a": 1}}\ndata: {"resp',
      final: false,
      want: { out: 'data: {"a":1}\n\n', rest: 'data: {"resp' },
    },
    {
      buffer: "data: [DONE]",
      final: true,
      want: { out: "data: [DONE]\n", rest: "" },
    },
  ];

  // Act
  const got = cases.map(({ buffer, final }) => ({
    buffer,
    final,
    want: unwrapSseChunk(buffer, final),
  }));

  // Assert
  deepStrictEqual(got, cases);
});
