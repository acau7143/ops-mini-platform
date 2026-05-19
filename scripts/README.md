# scripts/

운영 자동화를 위한 셸 스크립트 모음입니다.  
각 스크립트는 독립적으로 실행할 수 있으며 장애 대응 흐름에서 유기적으로 연결됩니다.

---

## 스크립트 목록

| 스크립트 | 목적 | 실행 권한 | 출력 위치 |
|---|---|---|---|
| `healthcheck.sh` | 서비스 상태 점검 (nginx, HTTP, 포트, 앱) | `sudo` 필요 | `evidence/{timestamp}-healthcheck/` |
| `log_snapshot.sh` | 장애 시점 시스템 상태 및 로그 수집 | `sudo` 필요 | `evidence/{timestamp}/` |
| `security-baseline.sh` | 보안 설정 자동 점검 | `sudo` 필요 | `evidence/security-{timestamp}/` |
| `deploy.sh` | 이미지 pull → 배포 → 헬스체크 → 자동 롤백 | `sudo` 권장 | `evidence/{timestamp}-deploy/` |

---

## 각 스크립트 상세

### healthcheck.sh

서버와 앱의 기본 상태를 자동으로 점검합니다.

**점검 항목**

- nginx 서비스 활성화 여부 (`systemctl is-active nginx`)
- localhost HTTP 응답 상태 (`curl` → 200 여부)
- 포트 80 리스닝 여부 (`ss -lntp`)
- 서버 업타임, 디스크, 메모리 정보
- nginx access / error 로그 최근 20줄
- Docker 컨테이너 상태 (`docker ps`)
- 앱 HTTP 응답 (`curl -I http://localhost:8080`)

**실행 방법**

```bash
sudo ./scripts/healthcheck.sh
```

**출력 파일**

```
evidence/{timestamp}-healthcheck/
├── result.txt        # 전체 점검 결과
└── fail_summary.txt  # 실패 항목만 요약 (실패 시에만 생성)
```

**연결 Runbook**: `runbook/baseline-check.md`

---

### log_snapshot.sh

장애 발생 시 시스템 상태와 로그를 한 번에 수집합니다.  
장애 직후 가장 먼저 실행하는 스크립트입니다.

**수집 항목**

- 시스템 상태: uptime, df, free, ss, nginx 상태, docker ps
- HTTP 응답: localhost(80), localhost:8080
- nginx 로그: access.log / error.log 최근 50줄
- Docker 앱 로그: test-app 컨테이너 최근 50줄

**실행 방법**

```bash
sudo ./scripts/log_snapshot.sh
```

**출력 파일**

```
evidence/{timestamp}/
├── system_state.txt      # 시스템 전반 상태
├── http_local.txt        # HTTP 응답 결과
├── nginx_access_tail.txt # nginx access 로그
├── nginx_error_tail.txt  # nginx error 로그
└── docker_app_logs.txt   # 컨테이너 로그
```

**연결 Runbook**: `runbook/baseline-check.md`, `runbook/nginx.md`

---

### security-baseline.sh

보안 설정 항목을 자동으로 점검하고 결과를 파일로 저장합니다.

**점검 항목**

| 번호 | 항목 | 기준 |
|---|---|---|
| 1 | SSH 비밀번호 인증 | 비활성화 여부 (`PasswordAuthentication no`) |
| 2 | UFW 방화벽 | 활성화 여부 |
| 3 | nginx worker 실행 계정 | `www-data` 여부 |
| 4 | nginx 설정 파일 권한 | others write 권한 없음 여부 |
| 5 | 열린 포트 목록 | 기록 전용 (PASS/FAIL 없음) |
| 6 | 스캐너 IP 접근 흔적 | access.log 기반 탐지 |

**실행 방법**

```bash
sudo ./scripts/security-baseline.sh
```

**출력 파일**

```
evidence/security-{timestamp}/
└── report.txt  # 점검 항목별 PASS/FAIL/WARN + 이상 항목 요약
```

**연결 Runbook**: `runbook/baseline-check.md`

---

### deploy.sh

이미지 pull부터 배포, 헬스체크, 자동 롤백까지 처리합니다.

**실행 흐름**

```
1. 배포 전 상태 기록 (before.txt)
2. docker compose pull
3. docker compose up -d
4. 헬스체크 (최대 3회 재시도, 3초 간격)
   ├── 성공 → after.txt 저장 후 종료 (exit 0)
   └── 실패 → 롤백 실행 후 종료 (exit 1)
```

**실행 방법**

```bash
./scripts/deploy.sh
```

**출력 파일**

```
evidence/{timestamp}-deploy/
├── before.txt   # 배포 전 컨테이너 상태
├── after.txt    # 배포 성공 시 컨테이너 상태
└── deploy.log   # 배포 전 과정 로그
```

**연결 Runbook**: `runbook/deploy.md`, `runbook/rollback.md`

---

## 장애 대응 시 권장 실행 순서

```
장애 감지
   ↓
1. sudo ./scripts/log_snapshot.sh   # 현재 상태 증거 먼저 확보
   ↓
2. sudo ./scripts/healthcheck.sh    # 어느 항목이 실패인지 확인
   ↓
3. 원인 분석 (nginx.md / docker.md runbook 참고)
   ↓
4. 복구 후 sudo ./scripts/healthcheck.sh 재실행   # 정상 복구 검증
```

배포 흐름:

```
./scripts/deploy.sh
   ↓ 실패 시
자동 롤백 실행
   ↓
sudo ./scripts/healthcheck.sh   # 롤백 후 상태 재확인
```

---

## 공통 주의사항

- `healthcheck.sh`, `log_snapshot.sh`, `security-baseline.sh` 는 `sudo` 로 실행해야 합니다.
- 모든 스크립트 출력은 `evidence/` 하위 디렉토리에 저장됩니다.
- `evidence/` 디렉토리는 프로젝트 루트 기준으로 실행해야 올바르게 저장됩니다.

```bash
# 프로젝트 루트에서 실행
cd ~/ops-mini-platform
sudo ./scripts/healthcheck.sh
```