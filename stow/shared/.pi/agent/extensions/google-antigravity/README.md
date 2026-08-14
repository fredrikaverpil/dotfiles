# google-antigravity (pi extension)

Use Gemini models in [pi](https://github.com/earendil-works/pi-mono) with a
personal Google account via Google's **Antigravity** OAuth flow — ported from
the opencode plugin
[opencode-antigravity-auth](https://github.com/NoeFabris/opencode-antigravity-auth).

> [!NOTE] Google's older "Gemini CLI" OAuth flow was shut down for consumer
> accounts on 2026-06-18
> ([deprecation notice](https://developers.google.com/gemini-code-assist/docs/deprecations/code-assist-individuals)).
> Antigravity OAuth is the successor and the only "login with personal Gmail"
> path that still works. Google considers using this flow from third-party tools
> a policy gray area — use at your own discretion.

## Usage

```
pi
/login google-antigravity        # browser OAuth (or manual paste for headless)
/model google-antigravity/gemini-3.1-pro
```

The model list is fetched from the account itself (`fetchAvailableModels`), not
hardcoded — Antigravity's ids come and go (`gemini-3-pro` is already retired in
favour of `gemini-3.1-pro`). Run `pi update --models` to refresh it; only
`gemini-*` ids are registered, since the proxy speaks the Gemini request shape
only.

Thinking level follows pi's reasoning setting, restricted per model to what
Antigravity accepts: `low`/`high` on pro (sent as the required `-low`/`-high`
model-id suffix), `minimal`/`low`/`medium`/`high` on bare flash ids, and none at
all for ids with the level baked in (`gemini-3.6-flash-medium`).

## How it works

1. OAuth (PKCE, Antigravity client id) with a localhost:51121 callback and a
   manual-paste fallback. The Cloud Code project id is discovered via
   `loadCodeAssist` (provisioned via `onboardUser` if the account has none) and
   stored alongside the refresh token in pi's `~/.pi/agent/auth.json`.
2. A local reverse proxy on 127.0.0.1 (ephemeral port) translates pi's built-in
   `google-generative-ai` adapter to the Cloud Code internal API
   (`cloudcode-pa`): wraps requests in `{project, model, request, ...}`, unwraps
   SSE `{"response": ...}` frames, and exchanges the `x-goog-api-key` header
   (the OAuth access token) for a `Bearer` token. Requests try the daily sandbox
   endpoint first, then prod.

## Configuration

- `PI_ANTIGRAVITY_PROJECT_ID` or `GOOGLE_CLOUD_PROJECT` — force a specific Cloud
  project id (needed for org-backed Code Assist Standard/Enterprise).
- `PI_ANTIGRAVITY_DEBUG=1` — write request/error traces to
  `$TMPDIR/pi-antigravity-debug.log`.
