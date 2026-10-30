#!/bin/bash
f=$(jq -r '.tool_input.file_path // empty')
[ -n "$f" ] && [ -f "$f" ] || exit 0
case "$f" in */dist/*|*/node_modules/*) exit 0 ;; esac
case "$f" in *.js|*.jsx|*.ts|*.tsx) ;; *) exit 0 ;; esac

d=$(dirname "$f")
while [ "$d" != "/" ] && [ ! -f "$d/package.json" ]; do d=$(dirname "$d"); done
[ "$d" = "/" ] && exit 0

# Formatting comes from ESLint's prettier/prettier rule; the root prettier bin is not executable.
# Findings are reported once per turn by lint-on-stop.sh, not after every edit.
(cd "$d" && npx --no-install eslint --fix --quiet "${f#"$d"/}") >/dev/null 2>&1 || true
