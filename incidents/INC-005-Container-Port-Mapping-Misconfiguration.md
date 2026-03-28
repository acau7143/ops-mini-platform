# INC-005 — Container Port Mapping Misconfiguration
 
## Summary
 
테스트 앱 컨테이너를 실행하는 과정에서 포트 매핑을 잘못 지정하여 `localhost:8080` 접속이 실패했다.
컨테이너 자체는 실행 중이었지만 요청이 실제 서비스가 동작하는 포트에 전달되지 않아 HTTP 접근이 불가능했다.
 
---
 
## Severity
 
**Low** — 의도적 재현 실습. 호스트 nginx 서비스에는 영향 없음.
 
| 등급 | SLA Response | SLA Resolution |
|------|-------------|----------------|
| Low | 인지 즉시 확인 | 당일 복구 |
 
---
 
## Impact
 
- 호스트에서 앱 컨테이너로의 HTTP 접근 불가
- 운영 중인 호스트 nginx에는 영향 없음
- reverse proxy(`/app`) 연결 전제 조건인 백엔드 앱 접근이 성립하지 않음
 
---
 
## Detection
 
```bash
docker ps                          # 컨테이너 Up 상태 확인
curl -I http://localhost:8080      # 접속 실패 확인
ss -lntp | grep 8080               # 포트 바인딩 상태 확인
docker logs test-app               # 컨테이너 로그 확인
```
 
---
 
## Timeline
 
| 순서 | 내용 |
|------|------|
| 1 | `-p 8080:8080` 으로 컨테이너 실행 |
| 2 | `docker ps` 로 컨테이너 Up 상태 확인 |
| 3 | `curl -I http://localhost:8080` 실패 확인 |
| 4 | 포트 매핑 재검토 → nginx 기본 포트가 80임을 확인 |
| 5 | 기존 컨테이너 삭제 후 `-p 8080:80` 으로 재실행 |
| 6 | `curl -I http://localhost:8080` → 200 OK 확인 |
 
---
 
## Symptoms
 
- 컨테이너는 실행 중(Up 상태)이었음
- 호스트의 8080 포트 접근 실패
- `docker logs` 에 요청 로그 없음 (요청이 컨테이너까지 도달하지 못함)
- 서비스가 죽은 것처럼 보였지만 실제 원인은 포트 매핑 오류
 
---
 
## Root Cause
 
nginx 컨테이너는 기본적으로 내부 80 포트에서 HTTP 서비스를 제공한다.
`-p 8080:8080` 설정은 호스트 8080 → 컨테이너 8080으로 전달하지만, 컨테이너 내부 8080 포트에는 서비스가 없기 때문에 HTTP 요청이 실패한다.
 
```
잘못된 설정:  host:8080 → container:8080  (nginx가 80에서만 수신)
올바른 설정:  host:8080 → container:80   (nginx 기본 포트와 일치)
```
 
---
 
## Recovery
 
```bash
docker rm -f test-app
docker run -d --name test-app -p 8080:80 nginx
```
 
---
 
## Validation After Recovery
 
```bash
docker ps                          # 0.0.0.0:8080->80/tcp 확인
curl -I http://localhost:8080      # HTTP/1.1 200 OK 확인
curl http://localhost:8080         # 앱 응답 본문 확인
docker logs test-app               # GET 요청 로그 기록 확인
```
 
검증 결과:
- `docker ps` 에서 `0.0.0.0:8080->80/tcp` 확인
- `curl -I http://localhost:8080` → `HTTP/1.1 200 OK`
- `docker logs` 에 요청 로그 기록 확인
 
---
 
## Prevention
 
- 컨테이너 실행 전 이미지의 내부 서비스 포트를 먼저 확인한다.
- `docker run` 명령의 `호스트포트:컨테이너포트` 순서를 반드시 재확인한다.
- 표준 컨테이너 이름과 표준 포트를 문서화한다.
- baseline check에 앱 컨테이너 상태와 앱 응답 검사를 추가한다.
 
---
 
## Evidence
 
![image.png](../evidence/day9-port-mapping-fail.png)
![image.png](../evidence/day9-app-container-curl-success.png)