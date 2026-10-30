#!/bin/bash
input=$(cat)
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ] && exit 0

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0

files=$( { git diff --name-only HEAD; git ls-files --others --exclude-standard; } \
  | grep -E '\.(js|jsx|ts|tsx)$' | grep -vE '(^|/)(dist|node_modules)/' | sort -u)
[ -z "$files" ] && exit 0

pairs=$(while IFS= read -r f; do
  [ -f "$f" ] || continue
  d=$(dirname "$f")
  while [ "$d" != "." ] && [ ! -f "$d/package.json" ]; do d=$(dirname "$d"); done
  [ "$d" = "." ] || printf '%s\t%s\n' "$d" "${f#"$d"/}"
done <<< "$files" | sort)
[ -z "$pairs" ] && exit 0

out=$(mktemp "${TMPDIR:-/tmp}/lint-on-stop.XXXXXX") || exit 0
trap 'rm -f "$out"' EXIT

printf '%s\n' "$pairs" | cut -f1 | uniq | while IFS= read -r d; do
  set --
  while IFS=$'\t' read -r pd rel; do
    [ "$pd" = "$d" ] && set -- "$@" "$rel"
  done <<< "$pairs"
  res=$(cd "$d" && npx --no-install eslint --quiet "$@" 2>&1)
  # Exit 2 is an ESLint crash or config error, not a finding; blocking on it would trap the turn.
  [ $? -eq 1 ] && printf '== %s\n%s\n\n' "$d" "$res" >> "$out"
done

state="$(git rev-parse --absolute-git-dir)/claude-lint-on-stop.sha"
if [ ! -s "$out" ]; then
  rm -f "$state"
  exit 0
fi

# An error the user already accepted would otherwise block every following turn once.
sha=$(shasum < "$out" | cut -d' ' -f1)
[ "$(cat "$state" 2>/dev/null)" = "$sha" ] && exit 0
printf '%s' "$sha" > "$state"

jq -n --rawfile r "$out" '{
  decision: "block",
  reason: ("ESLint errors in files changed since HEAD. Fix the ones this change caused; for errors that were already there, say so and leave them.\n\n" + $r)
}'
