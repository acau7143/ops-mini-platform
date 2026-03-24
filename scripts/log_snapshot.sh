#!/usr/bin/env bash
set -euo pipefail

TS="$(date '+%F %H:%M:%S')"
OUTDIR="evidence/$TS"

# script 실행 할 때 sudo 를 붙였는지 검사
if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo"
  exit 1
fi


mkdir -p "$OUTDIR"

echo "[정보] 스냅샷 디렉토리: $OUTDIR"

# ===== 1. 시스템 상태 =====

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

  echo "===== docker ps ===== "
  docker ps || true

} > "$OUTDIR/system_state.txt" 2>&1

# ===== 2. HTTP 응답 =====
{
  echo "===== curl -I http://localhost ====="
  curl -I http://localhost || true
  echo

  echo "===== curl -I http://localhost:8080 ====="
  curl -I http://localhost:8080 || true
} > "$OUTDIR/http_local.txt" 2>&1


# ===== 3. Nginx 로그 =====
{
  echo "===== nginx access.log (tail -n 50) ====="
  tail -n 50 /var/log/nginx/access.log || true
} > "$OUTDIR/nginx_access_tail.txt" 2>&1

{
  echo "===== nginx error.log (tail -n 50) ====="
  tail -n 50 /var/log/nginx/error.log || true
} > "$OUTDIR/nginx_error_tail.txt" 2>&1

# ===== 4. Docker 컨테이너 로그 (Day12 추가) =====
{
  echo "===== docker logs test-app (tail 50) ====="
  docker logs --tail 50 test-app 2>&1 || echo "[WARN] test-app 컨테이너가 없거나 실행 중이지 않습니다."


} > "$OUTDIR/docker_app_logs.txt" 2>&1

echo "[완료] $OUTDIR에 저장 되었습니다."
