# Testing

## Standard quality gates

Use the repo root `make` targets as the canonical validation entrypoints:

```bash
make quality
make quality-full
```

`make quality` runs the deterministic checks that also back CI:

- Python syntax compilation for the helper and standalone oracle
- JSON validation for the plugin manifest and repo-local marketplace entry

`make quality-full` adds local smoke checks that do not require a signed-in ChatGPT session:

- repo-local marketplace installation into a disposable `CODEX_HOME`
- unsupported-path validation with an empty `CODEX_HOME`

## Live authenticated validation

These checks require a Codex login with available usage and should be run when changing helper behavior or skill routing:

1. Compare the packaged helper and the standalone oracle on the same machine:

   ```bash
   python3 plugins/codex-rate-limits/skills/check-codex-rate-limits/scripts/read_rate_limits.py --json --utc
   python3 devel/codex-rate-limits.py --json --utc
   ```

2. Install the plugin into a fresh `CODEX_HOME` while reusing your existing auth:

   ```bash
   tmp_home="$(mktemp -d)"
   cp "${CODEX_HOME:-$HOME/.codex}/auth.json" "$tmp_home/auth.json"
   CODEX_HOME="$tmp_home" codex plugin marketplace add "$PWD"
   ```

3. Exercise both an explicit and a natural-language prompt in a fresh Codex session:

   ```bash
   tmp_workdir="$(mktemp -d)"
   CODEX_HOME="$tmp_home" codex exec \
     --skip-git-repo-check \
     --dangerously-bypass-approvals-and-sandbox \
     -C "$tmp_workdir" \
     "check my 5h and weekly rate limits"
   CODEX_HOME="$tmp_home" codex exec \
     --skip-git-repo-check \
     --dangerously-bypass-approvals-and-sandbox \
     -C "$tmp_workdir" \
     "do I have Codex room left today?"
   ```

4. Confirm the answers report the `5h` and `Weekly` ChatGPT subscription windows from the packaged helper, not API RPM/TPM limits.
