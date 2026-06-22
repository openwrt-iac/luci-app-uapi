#!/bin/sh
# Static checks for the LuCI app: JSON validity, JS syntax, ucode syntax, and
# the no-em-dash house style. No OpenWrt toolchain required; runs anywhere with
# ucode + node. Used by CI (lint job) and runnable locally.
set -eu

cd "$(dirname "$0")/.."
fail=0

note() { printf '%s\n' "$*"; }

# 1. House style: no em-dashes in any tracked file.
EMDASH=$(printf '\xe2\x80\x94')
emhits=$(git ls-files -z | xargs -0 grep -nH "$EMDASH" 2>/dev/null || true)
if [ -n "$emhits" ]; then
	printf '%s\n' "$emhits"
	note "FAIL: em-dash found (house style forbids em-dashes; use ': ' or '(...)')"
	fail=1
fi

# 2. JSON validity (menu.d, acl.d, any other JSON under root/).
for f in $(find root -name '*.json'); do
	if ! node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))" 2>/tmp/json.err; then
		note "FAIL: invalid JSON: $f"; cat /tmp/json.err; fail=1
	fi
done

# 3. Client view syntax (node parses CommonJS, so top-level `return` is allowed).
for f in $(find htdocs -name '*.js'); do
	if ! node --check "$f" 2>/tmp/js.err; then
		note "FAIL: JS syntax: $f"; cat /tmp/js.err; fail=1
	fi
done

# 4. ucode rpcd backend syntax. `ucode -c` resolves ES imports, but the uci/fs
# modules are OpenWrt-only and absent on a lint host, so strip the import and
# shebang lines first (undefined globals are fine at compile time) and
# compile-check the body.
for f in $(find root -name '*.uc'); do
	tmp=$(mktemp)
	sed "/^#!/d; /^import .* from '[a-z]*';\$/d" "$f" > "$tmp"
	if ! ucode -c -o /dev/null "$tmp" 2>/tmp/uc.err; then
		note "FAIL: ucode syntax: $f"; cat /tmp/uc.err; fail=1
	fi
	rm -f "$tmp"
done

# 5. VERSION is a single clean semver line (the Makefile and release tag read it).
VER=$(sed -n '1p' VERSION)
if ! printf '%s' "$VER" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
	note "FAIL: VERSION must be a single x.y.z line, got: '$VER'"
	fail=1
fi

[ "$fail" = 0 ] && note "lint: OK"
exit "$fail"
