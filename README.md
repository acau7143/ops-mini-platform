# Ops Mini Platform (12주)



시스템엔지니어 취업 포트폴리오를 목표로 한 12주 운영형 인프라 프로젝트입니다.

단순 구축이 아니라 운영(Runbook) + 장애대응(Incident) + 재현성(IaC) 을 증명하는 것을 목표로 합니다.



## 목표

- 리눅스 서버 운영/점검/복구 능력 강화

- 의도적 장애 재현 → 원인 분석 → 복구 → 재발 방지 문서화

- Terraform 기반 재현 가능한 인프라(IaC) 구축



## 현재 진행 상황

- Day1: EC2 접속 및 Nginx 실행 확인, `curl -I http://localhost` → 200 OK
- Day2: 외부(Public IP) HTTP 접근 확인, UFW로 80 차단/복구 재현, 첫 Incident 문서 작성
- Day3: `healthcheck.sh` 작성 nginx active / localhost HTTP 응답 / port 80 listening 자동 확인 시작
- Day4-5: Nginx 설정 백업 및 `nginx -t` 검증 절차 고정, 문법 오류 재현/복구 수행, SSH 보안 설정 1차 적용 및 안전 재접속 절차 문서화
- Day6: `healthcheck.sh` 업그레이드, `log_snapshot.sh` 작성, `/app/` reverse proxy 설정으로 502 재현 및 증거 수집, incident 문서화
- Day7: Runbook 목차 정리, Week1 회고 작성, 기존 incident 재리허설
- Day8: Docker Engine 설치, `docker version`/`docker ps` 검증, Docker 서비스 stop/start 장애 재현 및 복구
- Day9: 테스트 앱 컨테이너 실행, 포트 매핑 8080:8080 오류 재현 후 8080:80으로 수정하여 복구
- Day10: Nginx `/app` reverse proxy를 Docker 앱(`127.0.0.1:8080`)에 연결하고, upstream 포트 오타로 `502 Bad Gateway`를 재현한 뒤 `error.log` 확인 후 복구

## 레포 구조

- `runbook/` : 운영 절차(접속/배포/점검/복구)
- `incidents/` : 장애 기록(증상, 원인, 복구, 재발 방지)
- `evidence/` : 검증 결과 및 스크린샷/출력 캡처
- `decisions/` : 의사결정 기록(왜 이렇게 설계했는지)
- `diary/` : 일일 기록(진행 로그)





