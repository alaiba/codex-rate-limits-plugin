SHELL := /bin/bash

PYTHON ?= python3
ORACLE := devel/codex-rate-limits.py
HELPER := plugins/codex-rate-limits/skills/check-codex-rate-limits/scripts/read_rate_limits.py
PLUGIN_MANIFEST := plugins/codex-rate-limits/.codex-plugin/plugin.json
MARKETPLACE := .agents/plugins/marketplace.json

.PHONY: quality quality-full python-smoke json-smoke plugin-install-smoke no-auth-smoke

quality: python-smoke json-smoke

quality-full: quality plugin-install-smoke no-auth-smoke

python-smoke:
	$(PYTHON) -m py_compile $(ORACLE) $(HELPER)

json-smoke:
	$(PYTHON) -m json.tool $(PLUGIN_MANIFEST) >/dev/null
	$(PYTHON) -m json.tool $(MARKETPLACE) >/dev/null

plugin-install-smoke:
	tmpdir=$$(mktemp -d); \
	trap 'rm -rf "$$tmpdir"' EXIT; \
	CODEX_HOME="$$tmpdir" codex plugin marketplace add $(CURDIR)

no-auth-smoke:
	tmpdir=$$(mktemp -d); \
	trap 'rm -rf "$$tmpdir"' EXIT; \
	if CODEX_HOME="$$tmpdir" $(PYTHON) $(HELPER) --json --utc >"$$tmpdir/stdout.log" 2>"$$tmpdir/stderr.log"; then \
		echo "expected helper to fail without Codex auth"; \
		exit 1; \
	fi; \
	grep -Eq 'codex login|account/read failed|account/rateLimits/read failed' "$$tmpdir/stderr.log"
