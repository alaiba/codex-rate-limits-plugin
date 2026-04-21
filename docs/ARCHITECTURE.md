# Architecture

## Scope

`codex-rate-limits` is a single-purpose plugin that reports current Codex ChatGPT subscription usage windows. It is intentionally limited to the subscription `5h` and `Weekly` windows exposed by the local Codex app-server and does not cover API RPM/TPM limits, UI scraping, or any external service.

## Runtime model

The plugin keeps its runtime surface intentionally small:

- one installable plugin under `plugins/codex-rate-limits/`
- one canonical skill at `plugins/codex-rate-limits/skills/check-codex-rate-limits/SKILL.md`
- one stdlib-only helper at `plugins/codex-rate-limits/skills/check-codex-rate-limits/scripts/read_rate_limits.py`

The skill is the canonical authoring surface. The helper owns the executable behavior so the JSON-RPC flow, normalization rules, and failure handling stay versioned and testable instead of living inline in markdown.

## Helper interface

The packaged helper supports these flags:

- `--json` to emit the normalized report as JSON
- `--utc` to render reset timestamps in UTC instead of local time
- `--timeout <seconds>` to control how long the helper waits for `codex app-server` responses; the default is `10.0`

Human-readable output prioritizes the current account or plan, then the current rate-limit windows, credits, and any `rate_limit_reached_type` value returned by the API.

## Data model

The normalized report includes:

- `account`
- `limit_id`
- `limit_name`
- `plan_type`, preferring `rateLimits.planType` and falling back to `account.planType`
- `rate_limit_reached_type`
- `credits`
- `primary`
- `secondary`
- `raw`

Each populated window includes:

- `name`
- `used_percent`
- `remaining_percent`
- `window_duration_mins`
- `resets_at_unix`
- `resets_at`

See `plugins/codex-rate-limits/skills/check-codex-rate-limits/references/app-server-contract.md` for the request sequence and normalization details.

## Design constraints

- Prefer the local `codex app-server` JSON-RPC path over scraping or a second acquisition method.
- Keep the packaged runtime self-contained; the plugin must not depend on repo-local development files at runtime.
- Keep scripting minimal; one small helper is the maximum intended runtime surface.
- Keep the canonical skill only inside the plugin package; do not duplicate it under other repo-specific skill trees.
- Keep the plugin content portable so `plugins/codex-rate-limits/` can be copied into another repo or a home-local plugin directory without code changes.

## Compatibility notes

- Native Windows is a first-class runtime target.
- On Windows, helper startup prefers `codex.exe`, then `codex.ps1`, then `codex` to avoid older shim resolution issues.
- The helper uses thread-backed stream readers for subprocess stdout and stderr, which avoids the Windows pipe issues seen with selector-based implementations.
- The current supported app-server launch shape is `codex app-server`.
- The current repo validation entrypoint is `python3 scripts/quality.py`; the project no longer depends on `make`.

## Out of scope

- Reporting OpenAI API throughput limits
- Adding hooks, MCP servers, apps, or extra helper executables to this plugin
- Building a daemon, web UI, or background monitor around the rate-limit checks
