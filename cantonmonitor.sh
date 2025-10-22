#!/usr/bin/env bash
# v1.1.7
set -Eeuo pipefail

# ===================== Config (edit these) =====================
KEY_ID="val_XXXXXX"
SECRET="<put-shared-secret-here>"
BACKEND_BASE="https://api.cantonmonitor.com"

# If set, we query this to detect validator/container health and get the version.
# Example: VERSION_URI="https://node21.alumlabs.io/api/validator/version"
VERSION_URI=""

# Timeout (seconds) and TLS behavior
TIMEOUT=6
INSECURE=0
# ===================== End Config ==============================

# Fixed version file relative to this script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
VERSION_FILE="$SCRIPT_DIR/splice_node/VERSION"

# Binaries
for bin in curl jq awk df; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERROR: $bin is required." >&2; exit 1; }
done
[[ -n "$KEY_ID" ]] || { echo "ERROR: set KEY_ID in the script."; exit 2; }
[[ -n "$SECRET" ]] || { echo "ERROR: set SECRET in the script."; exit 2; }

ENDPOINT="${BACKEND_BASE%/}/health"
curl_flags=(-sS --max-time "$TIMEOUT" -H "User-Agent: cantonmonitor/1.0")
[[ "$INSECURE" == "1" ]] && curl_flags+=(-k)

trim() { awk '{$1=$1}1'; }
pick_version() {
  local s="${1:-}"
  [[ -n "$s" ]] || { echo ""; return; }
  awk '{
    match($0, /[0-9]+(\.[0-9]+){1,3}/, m);
    if (m[0]!="") { print m[0]; exit }
  }' <<<"$s"
}

# ------- Version + validator status -------
canton_up=false
version_value=""

if [[ -n "$VERSION_URI" ]]; then
  # Status check enabled
  http_out="$(curl -fsS -k --max-time "$TIMEOUT" "$VERSION_URI" 2>/dev/null || true)"
  if [[ -n "$http_out" ]]; then
    # Only true if JSON contains a "version"
    ver_from_json="$(jq -er '.version // empty' <<<"$http_out" 2>/dev/null || true)"
    if [[ -n "$ver_from_json" ]]; then
      version_value="$(pick_version "$ver_from_json")"
      if [[ -n "$version_value" ]]; then
        canton_up=true
      fi
    fi
  fi
else
  # Status check disabled
  canton_up=true
fi

# Fallback to version file if needed
if [[ -z "$version_value" && -r "$VERSION_FILE" ]]; then
  raw="$(tr -d '\r\n' < "$VERSION_FILE" | trim || true)"
  version_value="$(pick_version "$raw")"
fi

# Final fallback
[[ -n "$version_value" ]] || version_value="0.0.00"
version_json="$(jq -Rn --arg v "$version_value" '$v')"

# ------- System status -------
load_json="null"
if [[ -r /proc/loadavg ]]; then
  read -r l1 l5 l15 _ < /proc/loadavg || true
  load_json="$(jq -n --arg l1 "$l1" --arg l5 "$l5" --arg l15 "$l15" \
    '{one:($l1|tonumber), five:($l5|tonumber), fifteen:($l15|tonumber)}')"
fi

mem_json="null"
if [[ -r /proc/meminfo ]]; then
  mt=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
  ma=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
  if [[ -n "${mt:-}" && -n "${ma:-}" ]]; then
    used=$((mt-ma))
    pct=$(awk -v t="$mt" -v u="$used" 'BEGIN{printf "%.1f",(u*100)/t}')
    mem_json="$(jq -n --arg mt "$mt" --arg used "$used" --arg pct "$pct" \
      '{total_mb:(($mt|tonumber)/1024|floor), used_mb:(($used|tonumber)/1024|floor), percent:($pct|tonumber)}')"
  fi
fi

disk_json="null"
if read -r _ total used _ < <(df -kP / | awk 'NR==2{print $6" "$2" "$3" "$5}'); then
  if [[ -n "${total:-}" && -n "${used:-}" ]]; then
    tg=$(awk -v k="$total" 'BEGIN{printf "%.2f", k/1024/1024}')
    ug=$(awk -v k="$used"  'BEGIN{printf "%.2f", k/1024/1024}')
    pct=$(awk -v t="$total" -v u="$used" 'BEGIN{printf "%.1f",(u*100)/t}')
    disk_json="$(jq -n --arg tg "$tg" --arg ug "$ug" --arg pct "$pct" \
      '{"/":{total_gb:($tg|tonumber), used_gb:($ug|tonumber), percent:($pct|tonumber)}}')"
  fi
fi

uptime_json="null"
[[ -r /proc/uptime ]] && uptime_json="$(awk '{print int($1)}' /proc/uptime)"

status_json="$(jq -n --argjson load "$load_json" \
                    --argjson mem  "$mem_json" \
                    --argjson disk "$disk_json" \
                    --argjson up   "$uptime_json" \
  '{system:{load_avg:$load,mem:$mem,disk:$disk,uptime_s:$up}}')"

# ------- Payload & POST -------
ts="$(date +%s)"
payload="$(jq -n \
  --arg ts "$ts" \
  --argjson version "$version_json" \
  --argjson status "$status_json" \
  --argjson canton_up "$canton_up" \
  '{ts:($ts|tonumber), version:$version, status:$status, canton_up:$canton_up}')"

headers=(-H 'Content-Type: application/json'
         -H "X-Key-Id: $KEY_ID"
         -H "X-Signature: $SECRET"
         -H "X-Timestamp: $ts")

tmp="$(mktemp -t cantonmonitor.XXXXXX)"; trap 'rm -f "$tmp"' EXIT
http_code="$(curl "${curl_flags[@]}" -w '%{http_code}' -o "$tmp" \
  -X POST "${headers[@]}" -d "$payload" "$ENDPOINT" || true)"
body="$(cat "$tmp" || true)"

jq -n --argjson post_status "$http_code" --arg backend_response "$body" --argjson payload "$payload" \
  '{post_status:$post_status, backend_response:$backend_response, payload:$payload}'

[[ "$http_code" =~ ^2 ]] || exit 1

