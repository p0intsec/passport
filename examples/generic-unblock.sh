#!/usr/bin/env bash
# Example hook for `passport trap-test --on-finish ./examples/generic-unblock.sh`.
#
# After the run, the origin used for the test stays blocked by YOUR protection.
# This script shows the shape: find the captured IP (in your logs/API, starting
# at PC_START_MS) and request the unblock. Adapt both functions to your product.
#
# Variables provided by passport:
#   PC_HOST, PC_PATH, PC_START_MS, PC_IP (check-host only),
#   PC_PROBE_COUNTRY, PC_PROBE_ASN, PC_PROBE_NETWORK
set -euo pipefail

find_ip() {
  # check-host gives the IP directly; for Globalping, query your protection's log:
  # captures on $PC_HOST + $PC_PATH after $PC_START_MS (ASN $PC_PROBE_ASN).
  if [[ -n "${PC_IP:-}" ]]; then echo "$PC_IP"; return; fi
  curl -s "https://my-protection.example/api/captures?host=$PC_HOST&path=$PC_PATH&since=$PC_START_MS" \
    -H "Authorization: Bearer ${MY_TOKEN:?set MY_TOKEN}" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d[-1]['ip'] if d else '')"
}

unblock() {
  curl -s -X POST "https://my-protection.example/api/unblock" \
    -H "Authorization: Bearer ${MY_TOKEN:?set MY_TOKEN}" -H "Content-Type: application/json" \
    -d "{\"ip\":\"$1\",\"reason\":\"passport test\"}"
}

ip=$(find_ip)
if [[ -z "$ip" ]]; then echo "     test IP not found — unblock it manually"; exit 1; fi
echo "     unblocking $ip ($PC_PROBE_COUNTRY AS$PC_PROBE_ASN $PC_PROBE_NETWORK)"
unblock "$ip" >/dev/null
