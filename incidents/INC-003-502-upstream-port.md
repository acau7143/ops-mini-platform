# INC-003 — 502 Bad Gateway (Wrong upstream port)
 
## Summary
 
Day6 실습 중 nginx에 `/app/` reverse proxy 설정을 추가한 뒤, `proxy_pass` 대상 포트를 일부러 잘못 지정하여 502 Bad Gateway를 재현했다.
nginx error.log와 snapshot 스크립트로 증거를 수집하고, 설정을 원복하여 복구했다.
 
---
 
## Severity
 
**Low** — 의도적 재현 실습. `/app/` 경로만 영향, 메인 서비스(`/`) 정상 유지.
 
| 등급 | SLA Response | SLA Resolution |
|------|-------------|----------------|
| Low | 인지 즉시 확인 | 당일 복구 |
 
---
 
## Impact
 
- `/app/` 경로 요청이 정상 처리되지 않음
- 메인 정적 페이지(`/`)는 정상 유지
- nginx 서비스 자체는 살아 있었지만 upstream 연결 실패로 502 발생
 
---
 
## Detection
 
```bash
curl -I http://localhost/app/              # 502 Bad Gateway 확인
./scripts/log_snapshot.sh                  # 장애 시점 증거 수집
sudo tail -n 50 /var/log/nginx/error.log  # upstream 연결 실패 로그 확인
```
 
---
 
## Timeline
 
| 순서 | 내용 |
|------|------|
| 1 | nginx 설정에 `/app/` reverse proxy location 추가 |
| 2 | `proxy_pass http://127.0.0.1:9999;` 로 잘못된 포트 설정 |
| 3 | `sudo nginx -t` 문법 확인 (문법은 정상) |
| 4 | `sudo systemctl reload nginx` |
| 5 | `curl -I http://localhost/app/` → 502 Bad Gateway 확인 |
| 6 | `log_snapshot.sh` 실행 및 `error.log` 확인 |
| 7 | `/app/` 설정을 정상 포트로 수정 |
| 8 | `sudo nginx -t && sudo systemctl reload nginx` |
| 9 | 복구 후 healthcheck 및 재검증 수행 |
 
---
 
## Symptoms
 
- `curl -I http://localhost/app/` 실행 시 `502 Bad Gateway` 반환
- nginx error.log에 upstream 연결 실패 로그 기록
  - `connect() failed (111: Connection refused) while connecting to upstream`
- nginx 서비스 자체는 active 상태 유지
 
---
 
## Root Cause
 
`location /app/` 블록의 `proxy_pass` 가 실제 서비스가 없는 포트(9999)를 가리키도록 설정되어 있었다.
nginx는 요청을 받았지만 backend upstream에 연결할 수 없어 502를 반환했다.
`nginx -t` 는 문법만 검사하므로 포트 존재 여부는 탐지하지 못한다.
 
---
 
## Recovery
 
```bash
# proxy_pass 정상 포트로 수정
sudo nginx -t
sudo systemctl reload nginx
```
 
---
 
## Validation After Recovery
 
```bash
systemctl is-active nginx          # nginx active 확인
curl -I http://localhost           # 메인 페이지 200 OK
curl -I http://localhost/app/      # /app/ 정상 응답 확인
sudo tail -n 20 /var/log/nginx/error.log  # 추가 에러 없음 확인
```
 
검증 결과:
- nginx active 상태 유지
- `curl -I http://localhost` → 200 OK
- `/app/` 관련 설정 원복 후 기존 nginx 동작 정상 확인
 
---
 
## Prevention
 
- reverse proxy 실습 전 실제 backend 포트 존재 여부를 먼저 확인한다.
- nginx 설정 변경 후 항상 `nginx -t` 후 reload 한다.
- 장애 발생 즉시 `log_snapshot.sh` 로 증거를 수집한다.
- 502 발생 시 nginx 문제인지 upstream 문제인지 분리해서 확인한다.
 
---
 
## Evidence
 
- `evidence/<timestamp>/system_state.txt`
- `evidence/<timestamp>/http_local.txt`
- `evidence/<timestamp>/nginx_error_tail.txt`
 
![image.png](../evidence/day6-CURL-502-error.png)
![image.png](../evidence/day6-errorlog.png)