#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CACHE_FILE="/tmp/claude_ratelimit_cache.json"
CACHE_TTL=300

get_tmux_option() {
  local option=$1
  local default_value=$2
  local option_value
  option_value=$(tmux show-option -gqv "$option")
  if [[ -z "$option_value" ]]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

refresh_cache() {
  local TOKEN HEADERS_FILE
  TOKEN=$(python3 "$current_dir/claude_parse.py" read-token "$HOME/.claude/.credentials.json")
  [[ -z "$TOKEN" ]] && return

  HEADERS_FILE=$(mktemp /tmp/claude_headers_XXXXX)
  curl -s -D "$HEADERS_FILE" -o /dev/null \
    -X POST "https://api.anthropic.com/v1/messages" \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"x"}]}' \
    --max-time 10 2>/dev/null

  python3 "$current_dir/claude_parse.py" refresh-cache "$HEADERS_FILE" "$CACHE_FILE"
  rm -f "$HEADERS_FILE"
}

main() {
  local RATE label now cache_ts output pct_num
  RATE=$(get_tmux_option "@dracula-refresh-rate" 5)
  label=$(get_tmux_option "@dracula-claude-usage-label" "Claude")

  now=$(date +%s)
  cache_ts=$(python3 "$current_dir/claude_parse.py" cache-ts "$CACHE_FILE")

  if [[ $((now - cache_ts)) -ge $CACHE_TTL ]]; then
    refresh_cache
  fi

  output=$(python3 "$current_dir/claude_parse.py" format-output "$CACHE_FILE")
  pct_num=$(echo "$output" | grep -oP '^\d+' 2>/dev/null || echo "")

  if [[ -n "$pct_num" ]] && [[ "$pct_num" -ge 90 ]]; then
    echo "#[fg=#f8f8f2,bg=#ff5555]${label} ${output}"
  elif [[ -n "$pct_num" ]] && [[ "$pct_num" -ge 80 ]]; then
    echo "#[fg=#282a36,bg=#f1fa8c]${label} ${output}"
  else
    echo "${label} ${output}"
  fi

  sleep "$RATE"
}

main
