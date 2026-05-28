#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CACHE_FILE="/tmp/claude_ratelimit_cache.json"

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

main() {
  local RATE label output pct_num
  RATE=$(get_tmux_option "@dracula-refresh-rate" 5)
  label=$(get_tmux_option "@dracula-claude-weekly-label" "weekly")

  output=$(python3 "$current_dir/claude_parse.py" format-output-7d "$CACHE_FILE")
  pct_num=$(echo "$output" | grep -oP '^\d+' 2>/dev/null || echo "")

  if [[ -n "$pct_num" ]] && [[ "$pct_num" -ge 90 ]]; then
    echo "#[fg=#f8f8f2,bg=#ff5555]${label} ${output}"
  elif [[ -n "$pct_num" ]] && [[ "$pct_num" -ge 75 ]]; then
    echo "#[fg=#282a36,bg=#ffb86c]${label} ${output}"
  else
    echo "${label} ${output}"
  fi

  sleep "$RATE"
}

main
