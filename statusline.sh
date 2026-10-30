#!/usr/bin/env bash
input=$(cat)
cache_dir="$HOME/.cache/claude-statusline"
mkdir -p "$cache_dir"
printf '%s' "$input" > "$cache_dir/last-input.json"

j() { jq -r "$1" <<<"$input"; }

reset=$'\e[0m' dim=$'\e[2m' bold=$'\e[1m'
red=$'\e[31m' green=$'\e[32m' yellow=$'\e[33m' magenta=$'\e[35m' cyan=$'\e[36m'
sep="${dim} | ${reset}"

used_color() {
  local p=${1%.*}
  if [ "$p" -ge 80 ]; then printf '%s' "$red"
  elif [ "$p" -ge 50 ]; then printf '%s' "$yellow"
  else printf '%s' "$green"; fi
}

gradient_color() {
  awk -v p="$1" -v stops="$2" 'BEGIN {
    n = split(stops, s, " ")
    split("80 230 240 230", R, " "); split("200 200 140 60", G, " "); split("90 60 40 60", B, " ")
    if (p <= s[1]) { i = 1; t = 0 }
    else if (p >= s[n]) { i = n - 1; t = 1 }
    else { for (i = 1; i < n - 1; i++) if (p < s[i + 1]) break; t = (p - s[i]) / (s[i + 1] - s[i]) }
    printf "\033[38;2;%d;%d;%dm", R[i] + (R[i + 1] - R[i]) * t, G[i] + (G[i + 1] - G[i]) * t, B[i] + (B[i + 1] - B[i]) * t
  }'
}

# Colors by the use projected at reset, so a fast start shows before the limit is close.
pace_color() {
  gradient_color "$(awk -v used="$1" -v elapsed="$2" -v total="$3" 'BEGIN {
    f = elapsed / total
    if (f < 0.1) f = 0.1
    if (f > 1) f = 1
    print used / 100 / f
  }')" "0.7 0.9 1.05 1.25"
}

work_seconds() {
  local start=$1 end=$2 total=0 day d lo hi
  day=$(date -j -f '%Y-%m-%d %H:%M:%S' "$(date -r "$start" +%Y-%m-%d) 00:00:00" +%s)
  while [ "$day" -lt "$end" ]; do
    d=$(date -r "$day" +%Y-%m-%d)
    if [ "$(date -r "$day" +%u)" -le 5 ]; then
      lo=$(date -j -f '%Y-%m-%d %H:%M:%S' "$d 08:00:00" +%s)
      hi=$(date -j -f '%Y-%m-%d %H:%M:%S' "$d 18:00:00" +%s)
      [ "$lo" -lt "$start" ] && lo=$start
      [ "$hi" -gt "$end" ] && hi=$end
      [ "$hi" -gt "$lo" ] && total=$((total + hi - lo))
    fi
    day=$(date -j -v+1d -f '%Y-%m-%d %H:%M:%S' "$d 00:00:00" +%s)
  done
  echo "$total"
}

now=$(date +%s)
cwd=$(j '.workspace.current_dir')
model=$(j '.model.display_name')

printf '%s%s@%s%s %s%s%s' "$dim" "$(whoami)" "$(hostname -s)" "$reset" "$cyan" "${cwd/#$HOME/~}" "$reset"
branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null) && printf ' %s[%s]%s' "$magenta" "$branch" "$reset"
printf '\n'

printf '%s%s%s' "$bold" "$model" "$reset"

remaining=$(j '.context_window.remaining_percentage // empty')
toks=$(j 'if .context_window.total_input_tokens then "\((.context_window.total_input_tokens/100|round)/10)k" else empty end')
if [ -n "$remaining" ]; then
  # Answers degrade long before the window is full, so red starts at half of it.
  printf '%sctx:%s%s%%%s' "$sep" "$(gradient_color $((100 - ${remaining%.*})) "20 30 40 50")" "$remaining" "$reset"
  [ -n "$toks" ] && printf ' %s(%s)%s' "$dim" "$toks" "$reset"
fi

# Every window except spend_limit, so an undocumented per-model window shows up without a change here.
while IFS=$'\t' read -r key pct reset_at; do
  case "$key" in
    five_hour) label=5h; fmt='%H:%M' ;;
    seven_day) label=7d; fmt='%a %H:%M' ;;
    seven_day_*) label="7d-${key#seven_day_}"; fmt='%a %H:%M' ;;
    *) label="$key"; fmt='%a %H:%M' ;;
  esac
  if [ -z "$reset_at" ]; then color=$(used_color "$pct")
  elif [ "$key" = five_hour ]; then color=$(pace_color "$pct" $((18000 - (reset_at - now))) 18000)
  # A week holds 50 working hours (Mon–Fri, 08–18) wherever the window starts.
  elif [ "${key%%_day*}" = seven ]; then color=$(pace_color "$pct" "$(work_seconds $((reset_at - 604800)) "$now")" 180000)
  else color=$(used_color "$pct"); fi
  printf '%s%s:%s%.0f%%%s' "$sep" "$label" "$color" "$pct" "$reset"
  [ -n "$reset_at" ] && printf ' %s↻%s%s' "$dim" "$(date -r "$reset_at" "+$fmt")" "$reset"
done < <(j '.rate_limits // {} | to_entries[] | select(.key != "spend_limit" and .value.used_percentage != null) | [.key, .value.used_percentage, (.value.resets_at // "")] | @tsv')

# ccusage takes seconds, so it refreshes in the background and the line shows the last cached value.
week_reset=$(j '.rate_limits.seven_day.resets_at // empty')
if [ -n "$week_reset" ]; then
  since=$(date -r $((week_reset - 604800)) +%Y%m%d)
  cost_file="$cache_dir/cost-$since"
  lock="$cache_dir/cost.lock"
  if { [ ! -f "$cost_file" ] || [ $(( $(date +%s) - $(stat -f %m "$cost_file") )) -gt 300 ]; } && mkdir "$lock" 2>/dev/null; then
    (
      cost=$(cd "$cache_dir" && bun x ccusage@latest daily --since "$since" --json 2>/dev/null | jq -r '.totals.totalCost // empty')
      [ -n "$cost" ] && printf '%s' "$cost" > "$cost_file"
      rmdir "$lock"
    ) >/dev/null 2>&1 &
  fi
  [ -f "$cost_file" ] && printf '%s%s~$%.0f/7d%s' "$sep" "$dim" "$(cat "$cost_file")" "$reset"
fi
printf '\n'
