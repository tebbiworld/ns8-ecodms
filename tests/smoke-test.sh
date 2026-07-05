#!/bin/bash

#
# Copyright (C) 2026 tebbi
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Post-deploy smoke test for ns8-ecodms. Run in the module user context:
#   runagent -m ecodms1 bash /path/to/smoke-test.sh

set -u
PASS=0; FAIL=0
ok()  { echo "  PASS: $1"; PASS=$((PASS+1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

STATE="${HOME}/.config/state"
WEB_PORT="$(grep -oP '(?<=^WEB_PORT=).*' "${STATE}/environment" 2>/dev/null)"

echo "== ns8-ecodms smoke test (web ${WEB_PORT}) =="

echo "[1] container running"
st="$(podman inspect -f '{{.State.Status}}' ecodms-app 2>/dev/null)"
rc="$(podman inspect -f '{{.RestartCount}}' ecodms-app 2>/dev/null)"
[ "$st" = running ] && ok "ecodms-app running" || bad "ecodms-app not running ($st)"
[ "${rc:-9}" -le 2 ] 2>/dev/null && ok "restart count low ($rc)" || bad "restart looping ($rc)"

echo "[2] ecoDMS server ports listening (17001-17004)"
for p in 17001 17002 17003 17004; do
  if podman exec ecodms-app sh -c "true" 2>/dev/null; then :; fi
  if (echo > /dev/tcp/127.0.0.1/$p) 2>/dev/null; then ok "port $p open"; else bad "port $p not reachable"; fi
done

echo "[3] web client HTTP (8080 via ${WEB_PORT})"
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://127.0.0.1:${WEB_PORT}/ 2>/dev/null)"
[ -n "$code" ] && [ "$code" != "000" ] && ok "web answers (HTTP $code)" || bad "web no answer"

echo "[4] volumes present"
for v in ecodms-data ecodms-backup ecodms-restore ecodms-scaninput; do
  podman volume exists "$v" 2>/dev/null && ok "volume $v" || bad "volume $v missing"
done

echo "== result: ${PASS} passed, ${FAIL} failed =="
[ "${FAIL}" -eq 0 ]
