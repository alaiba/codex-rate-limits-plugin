# Testing

## Standard Validation

Use the repo root Python runner as the canonical validation entrypoint:

```bash
python3 scripts/quality.py ci
python3 scripts/quality.py local
```

`python3 scripts/quality.py ci` runs the deterministic checks that also back CI:

- Python syntax compilation for the packaged helper
- JSON validation for the plugin manifest and repo-local marketplace entry

`python3 scripts/quality.py local` adds local smoke checks that do not require a signed-in ChatGPT session:

- unsupported-path validation with an empty `CODEX_HOME`

The earlier repo-local plugin installation smoke check was removed from the standard local runner because the current Codex CLI no longer supports `codex plugin marketplace add`. Keep plugin-install validation separate until the current CLI exposes a supported local-plugin install path again.

## Live authenticated validation

These checks require a Codex login with available usage and should be run when changing helper behavior or skill routing:

1. Run the packaged helper directly:

   ```bash
   python3 plugins/codex-rate-limits/skills/check-codex-rate-limits/scripts/read_rate_limits.py --json --utc
   ```

2. Confirm the helper output includes the current subscription windows, reset times, and any available `plan_type`, `limit_id`, and credit fields for the signed-in account.

3. Exercise both an explicit and a natural-language prompt in a fresh Codex session from the repo root:

   ```bash
   codex exec \
     --skip-git-repo-check \
     --dangerously-bypass-approvals-and-sandbox \
     -C "$PWD" \
     "check my 5h and weekly rate limits"
   codex exec \
     --skip-git-repo-check \
     --dangerously-bypass-approvals-and-sandbox \
     -C "$PWD" \
     "do I have Codex room left today?"
   ```

4. Confirm the answers report the `5h` and `Weekly` ChatGPT subscription windows from the packaged helper, not API RPM/TPM limits.

5. If Codex exposes a supported local-plugin install flow again, add that command back as a separate plugin-routing validation step before treating marketplace installation as covered.
