#!/usr/bin/env bash

# 색상 정의 (터미널에서 색깔로 표시)
RED='\033[0;31m'      # 빨강 (실패)
GREEN='\033[0;32m'    # 초록 (성공)
YELLOW='\033[0;33m'   # 노랑 (경고)
NC='\033[0m'          # 색상 해제


# 현재 시간
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "================================="
echo "Baseline Check - $TIMESTAMP"
echo "================================="

# ===== Check 1: Nginx 상태 =====
RESULT=$(systemctl is-active nginx)

# 검사: nginx가 "active"인가?
if [[ "$RESULT" == "active" ]]; then
        echo -e "${GREEN}PASS${NC} nginx state = ${RESULT}"
        CHECK1=0
else
        echo -e "${RED}FAIL${NC} nginx state = ${RESULT}"
        CHECK1=1
fi


# ===== Check 2: HTTP 응답 상태 =====
STATE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)

# 검사: HTTP 상태가 "200"인가?
if [[ "$STATE" == "200" ]]; then
        echo -e "${GREEN}PASS${NC} nginx state = ${STATE}"
        CHECK2=0
else
        echo -e "${RED}FAIL${NC} nginx state = ${STATE}"
        CHECK2=1
fi


# ===== Check 3: 포트 80 리스닝 =====
# 포트가 리스닝 중이면 명령어가 0을 반환, 아니면 1 반환
if ss -lntp 2>/dev/null | grep -q ":80 "; then
    echo -e "${GREEN}PASS${NC} port 80 is listening"
    CHECK3=0
else
    echo -e "${RED}FAIL${NC} port 80 is NOT listening"
    CHECK3=1
fi
# ===== Check 4: 서버 업타임 =====
echo "4. Server Uptime"
uptime

# ===== Check 5: 디스크 사용량 =====
echo "5. Disk Usage (df -h)"
df -h

# ===== Check 6:  메모리 상태 =====
 echo "6. Memory (free -h)"
free -h


# ===== Check 7: nginx access log 최근 20줄 =====
echo "7. nginx Access Log (last 20 lines)"
tail -n 20 /var/log/nginx/access.log

# ===== Check 8: nginx error log 최근 20줄 =====
echo "8. nginx Error Log (last 20 lines)"
tail -n 20 /var/log/nginx/error.log

# ===== 최종 결과 =====
echo "=========================================="

# 3개 체크 중 몇 개 성공했는가?
TOTAL_PASS=$((3 - CHECK1 - CHECK2 - CHECK3))
echo "Result: $TOTAL_PASS / 3 checks passed"

# 3개 모두 성공? → 종료 코드 0 (성공)
# 하나라도 실패? → 종료 코드 1 (실패)
if [[ $CHECK1 -eq 0 && $CHECK2 -eq 0 && $CHECK3 -eq 0 ]]; then
    echo -e "${GREEN}Overall: PASS${NC}"
    exit 0
else
    echo -e "${RED}Overall: FAIL${NC}"
    exit 1
fi

