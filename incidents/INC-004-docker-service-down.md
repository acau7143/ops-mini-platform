# INC-004 — Docker service down
 
## Summary
 
Docker 서비스 중지 및 복구 절차를 실습하는 과정에서 `docker.service` 만 중지하면 Docker가 완전히 내려가지 않는다는 점을 확인했다.
`docker.socket` 까지 함께 중지해 실제 장애 상태를 재현했고, 재기동하여 정상 복구를 확인했다.
 
---
 
## Severity
 
**Low** — 의도적 재현 실습. Docker daemon 연결 실패 상태를 재현하고 복구함.
 
| 등급 | SLA Response | SLA Resolution |
|------|-------------|----------------|
| Low | 인지 즉시 확인 | 당일 복구 |
 
---
 
## Impact
 
- `docker ps` 등 Docker 명령 전체 실패
- 실행 중이던 컨테이너 서비스 접근 불가
- nginx 서비스 자체에는 영향 없음
 
---
 
## Detection
 
```bash
systemctl is-active docker         # inactive 확인
systemctl is-active docker.socket  # inactive 확인
sudo docker ps                     # Docker daemon 연결 실패 확인
```
 
---
 
## Timeline
 
| 순서 | 내용 |
|------|------|
| 1 | `sudo systemctl stop docker` 실행 |
| 2 | `docker.socket` 이 아직 active 상태라는 systemd 메시지 확인 |
| 3 | `sudo systemctl stop docker.socket` 추가 실행 |
| 4 | `systemctl is-active docker` / `docker.socket` → 모두 inactive 확인 |
| 5 | `sudo docker ps` 실행 → Docker daemon 연결 실패 확인 |
| 6 | `sudo systemctl start docker` / `docker.socket` 재기동 |
| 7 | `sudo docker ps` 정상 출력 확인 |
 
---
 
## Symptoms
 
- `sudo systemctl stop docker` 실행 시 아래 메시지 출력
  - `Stopping 'docker.service', but its triggering units are still active: docker.socket`
- `docker.service` 만 중지했을 때는 완전한 중단 상태가 아님
- `docker.socket` 까지 중지한 뒤 `sudo docker ps` 실행 시 Docker daemon 연결 실패 발생
 
---
 
## Root Cause
 
Docker는 `docker.service` 와 `docker.socket` 이 함께 동작하는 구조다.
`docker.service` 만 중지하면 `docker.socket` 이 살아 있어 요청이 들어올 때 서비스를 다시 깨울 수 있다.
완전한 장애 재현을 위해서는 service와 socket을 함께 중지해야 한다.
 
---
 
## Recovery
 
```bash
sudo systemctl start docker
sudo systemctl start docker.socket
```
 
---
 
## Validation After Recovery
 
```bash
systemctl is-active docker         # active 확인
systemctl is-active docker.socket  # active 확인
sudo docker ps                     # 정상 출력 확인
```
 
검증 결과:
- `docker` → active
- `docker.socket` → active
- `sudo docker ps` 정상 출력
 
---
 
## Prevention
 
- Runbook에 service와 socket을 함께 다루는 절차를 명시한다.
- Docker 장애 재현 및 점검 시 `docker.service` 와 `docker.socket` 상태를 함께 확인한다.
 
---
 
## Evidence
 
![image.png](../evidence/day8-docker-fail-recover.png)