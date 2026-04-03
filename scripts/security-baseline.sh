#!/usr/bin/env bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# sudo 체크
if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo"
  exit 1
fi

# 현재 시각 + 저장 경로 설정
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT_DIR="evidence/security-${TIMESTAMP}"
REPORT_FILE="${REPORT_DIR}/report.txt"

# 결과 저장 폴더 생성
mkdir -p "$REPORT_DIR"

# 실패/경고 항목 모아두는 변수 (나중에 마지막에 출력)
FAIL_SUMMARY=""

echo "================================="
echo "Security Baseline Check - $TIMESTAMP"
echo "================================="
# 파일에도 동시에 기록
echo "Security Baseline Check - $TIMESTAMP" > "$REPORT_FILE"

# ===== Check 1: SSH 비밀번호 인증 =====
RESULT=$(sudo sshd -T | grep passwordauthentication)
# sshd -T : 현재 SSH 설정을 전부 출력
# grep으로 passwordauthentication 줄만 뽑아냄

if echo "$RESULT" | grep -q "no"; then
  echo -e "${GREEN}[PASS]${NC} SSH 비밀번호 인증 비활성화"
  echo "[PASS] SSH 비밀번호 인증 비활성화" >> "$REPORT_FILE"
else
  echo -e "${RED}[FAIL]${NC} SSH 비밀번호 인증 활성화 상태"
  echo "[FAIL] SSH 비밀번호 인증 활성화 상태" >> "$REPORT_FILE"
  FAIL_SUMMARY="${FAIL_SUMMARY}\n- SSH 비밀번호 인증 활성화 상태"
fi


# ===== Check 2: UFW 활성화 상태 =====
UFW_STATUS=$(sudo ufw status | grep "Status")
# ufw status 출력에서 "Status" 줄만 뽑아냄
# 정상이면 "Status: active" 가 나옴

if echo "$UFW_STATUS" | grep -q "Status: active"; then
  echo -e "${GREEN}[PASS]${NC} UFW 활성화 상태"
  echo "[PASS] UFW 활성화 상태" >> "$REPORT_FILE"
else
  echo -e "${RED}[FAIL]${NC} UFW 비활성화 상태"
  echo "[FAIL] UFW 비활성화 상태" >> "$REPORT_FILE"
FAIL_SUMMARY="${FAIL_SUMMARY}\n- UFW 비활성화 상태"
fi


# ===== Check 3: nginx worker 실행 계정 =====
NGINX_WORKER=$(ps aux | grep "nginx: worker" | grep -v grep)
# ps aux : 전체 프로세스 목록
# grep "nginx: worker" : worker 프로세스만 뽑아냄
# grep -v grep : grep 명령어 자체가 목록에 잡히는 거 제거

if echo "$NGINX_WORKER" | grep -q "www-data"; then
  echo -e "${GREEN}[PASS]${NC} nginx worker가 www-data 계정으로 실행 중"
  echo "[PASS] nginx worker가 www-data 계정으로 실행 중" >> "$REPORT_FILE"
else
  echo -e "${RED}[FAIL]${NC} nginx worker 실행 계정 이상"
  echo "[FAIL] nginx worker 실행 계정 이상" >> "$REPORT_FILE"
  FAIL_SUMMARY="${FAIL_SUMMARY}\n- nginx worker 실행 계정 이상"
fi



# ===== Check 4: nginx 설정 파일 위험 권한 =====
DANGEROUS_FILES=$(find /etc/nginx -perm -o+w 2>/dev/null)
# find /etc/nginx : nginx 설정 디렉토리 탐색
# -perm -o+w : others(누구나)에게 write 권한 있는 파일 찾기
# 2>/dev/null : 권한 없어서 생기는 에러 메시지 버림

if [ -z "$DANGEROUS_FILES" ]; then
  # -z : 변수가 비어 있으면 true
  echo -e "${GREEN}[PASS]${NC} nginx 설정 파일 위험 권한 없음"
  echo "[PASS] nginx 설정 파일 위험 권한 없음" >> "$REPORT_FILE"
else
  echo -e "${RED}[FAIL]${NC} nginx 설정 파일 위험 권한 발견: $DANGEROUS_FILES"
  echo "[FAIL] nginx 설정 파일 위험 권한 발견: $DANGEROUS_FILES" >> "$REPORT_FILE"
  FAIL_SUMMARY="${FAIL_SUMMARY}\n- nginx 설정 파일 위험 권한: $DANGEROUS_FILES"
fi



# ===== Check 5: 열린 포트 목록 기록 =====
echo -e "${YELLOW}[INFO]${NC} 현재 열린 포트 목록 기록"
echo "[INFO] 현재 열린 포트 목록" >> "$REPORT_FILE"
ss -lntp >> "$REPORT_FILE"
# PASS/FAIL 판단 없이 현재 상태를 파일에 저장
# 날짜별로 포트 변화를 추적하는 증거 용도

# ===== Check 6: 취약점 스캐너 IP 접근 흔적 =====
SCANNER_IP="194.163.183.223"
SCANNER_HIT=$(grep "$SCANNER_IP" /var/log/nginx/access.log 2>/dev/null)
# access.log 에서 스캐너 IP 접근 기록 검색
# 2>/dev/null : access.log 읽기 실패 시 에러 메시지 버림

if [ -z "$SCANNER_HIT" ]; then
  echo -e "${GREEN}[PASS]${NC} 스캐너 IP 접근 흔적 없음"
  echo "[PASS] 스캐너 IP 접근 흔적 없음" >> "$REPORT_FILE"
else
  HIT_COUNT=$(echo "$SCANNER_HIT" | wc -l)
  # wc -l : 줄 수 세기 = 접근 횟수
  echo -e "${YELLOW}[WARN]${NC} 스캐너 IP 접근 흔적 발견: ${HIT_COUNT}건"
  echo "[WARN] 스캐너 IP 접근 흔적 발견: ${HIT_COUNT}건" >> "$REPORT_FILE"
  echo "$SCANNER_HIT" >> "$REPORT_FILE"
  FAIL_SUMMARY="${FAIL_SUMMARY}\n- 스캐너 IP 접근 흔적: ${HIT_COUNT}건"
fi



# ===== 최종 요약 =====
echo ""
echo "================================="
echo "결과 저장 위치: $REPORT_FILE"
echo "================================="

if [ -z "$FAIL_SUMMARY" ]; then
  # FAIL_SUMMARY 가 비어 있으면 전부 통과
  echo -e "${GREEN}이상 항목 없음${NC}"
  echo "이상 항목 없음" >> "$REPORT_FILE"
else
  echo -e "${RED}이상 항목 발견${NC}"
  echo -e "$FAIL_SUMMARY"
  # 파일에도 저장
  echo "이상 항목 발견" >> "$REPORT_FILE"
  echo -e "$FAIL_SUMMARY" >> "$REPORT_FILE"
fi
                                                          
