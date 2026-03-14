#!/usr/bin/env bash
set -euo pipefail

TS="$(date '+%F %H:%M:%S')"
OUTDIR="evidence/$TS"

mkdir -p "$OUTDIR"

echo "[정보] 스냅샷 디렉토리: $OUTDIR"

{
  echo "===== uptime ====="
  uptime
  echo
  echo "===== df -h ====="
  df -h
  echo
  echo "===== free -h ====="
  free -h
  echo
  echo "===== ss -lntp ====="
  ss -lntp
  echo
  echo "===== systemctl status nginx ====="
  systemctl status nginx --no-pager
} > "$OUTDIR/system_state.txt" 2>&1

{
  echo "===== curl -I http://localhost ====="
  curl -I http://localhost || true
} > "$OUTDIR/http_local.txt" 2>&1

{
  echo "===== nginx access.log (tail -n 50) ====="
  tail -n 50 /var/log/nginx/access.log || true
} > "$OUTDIR/nginx_access_tail.txt" 2>&1

{
  echo "===== nginx error.log (tail -n 50) ====="
  tail -n 50 /var/log/nginx/error.log || true
} > "$OUTDIR/nginx_error_tail.txt" 2>&1

echo "[완료] $OUTDIR에 저장 되었습니다."
