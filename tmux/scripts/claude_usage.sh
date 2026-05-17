#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

CACHE_FILE="/tmp/claude_ratelimit_cache.json"
CACHE_TTL=300  # atualiza a cada 5 minutos

refresh_cache() {
  TOKEN=$(python3 -c "
import json
try:
    d = json.load(open('/home/lucas/.claude/.credentials.json'))
    print(d['claudeAiOauth']['accessToken'])
except:
    print('')
" 2>/dev/null)
  [[ -z "$TOKEN" ]] && return

  HEADERS_FILE=$(mktemp /tmp/claude_headers_XXXXX)
  curl -s -D "$HEADERS_FILE" -o /dev/null \
    -X POST "https://api.anthropic.com/v1/messages" \
    -H "Authorization: Bearer $TOKEN" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d '{"model":"claude-haiku-4-5-20251001","max_tokens":1,"messages":[{"role":"user","content":"x"}]}' \
    --max-time 10 2>/dev/null

  python3 - "$HEADERS_FILE" "$CACHE_FILE" << 'PYEOF'
import json, time, re, sys

headers_file, cache_file = sys.argv[1], sys.argv[2]
try:
    with open(headers_file) as f:
        headers = f.read()

    def get_h(name):
        m = re.search(rf'^{re.escape(name)}:\s*(.+)$', headers, re.M | re.I)
        return m.group(1).strip() if m else None

    util_5h  = get_h('anthropic-ratelimit-unified-5h-utilization')
    reset_5h = get_h('anthropic-ratelimit-unified-5h-reset')
    util_7d  = get_h('anthropic-ratelimit-unified-7d-utilization')
    reset_7d = get_h('anthropic-ratelimit-unified-7d-reset')

    cache = {
        'ts':       int(time.time()),
        'util_5h':  round(float(util_5h) * 100) if util_5h  else None,
        'reset_5h': int(reset_5h)                if reset_5h else None,
        'util_7d':  round(float(util_7d) * 100) if util_7d  else None,
        'reset_7d': int(reset_7d)                if reset_7d else None,
    }
    json.dump(cache, open(cache_file, 'w'))
except Exception:
    pass
PYEOF

  rm -f "$HEADERS_FILE"
}

main() {
  RATE=$(get_tmux_option "@dracula-refresh-rate" 5)
  label=$(get_tmux_option "@dracula-claude-usage-label" "Claude")

  now=$(date +%s)

  # Atualiza cache se estiver velho (faz chamada à API, ~1-2s)
  cache_ts=0
  if [[ -f "$CACHE_FILE" ]]; then
    cache_ts=$(python3 -c "import json; print(json.load(open('$CACHE_FILE')).get('ts',0))" 2>/dev/null || echo 0)
  fi
  if [[ $((now - cache_ts)) -ge $CACHE_TTL ]]; then
    refresh_cache
  fi

  # Lê e formata a partir do cache
  output=$(python3 << 'PYEOF'
import json, time

try:
    d = json.load(open('/tmp/claude_ratelimit_cache.json'))
    util   = d.get('util_5h')
    reset  = d.get('reset_5h')

    if util is None:
        print("--")
    else:
        remaining_s = max(0, reset - int(time.time())) if reset else 0
        h = remaining_s // 3600
        m = (remaining_s % 3600) // 60
        tstr = f"~{h}h{m:02d}m" if h > 0 else f"~{m}m"
        print(f"{util}% {tstr}")
except Exception:
    print("--")
PYEOF
)

  pct_num=$(echo "$output" | grep -oP '^\d+' 2>/dev/null || echo "")

  if [[ -n "$pct_num" ]] && [[ "$pct_num" -ge 80 ]]; then
    echo "#[fg=#282a36,bg=#f1fa8c]${label} ${output}"
  else
    echo "${label} ${output}"
  fi

  sleep $RATE
}

main
