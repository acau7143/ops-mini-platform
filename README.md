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


## 레포 구조

- `runbook/` : 운영 절차(접속/배포/점검/복구)
- `incidents/` : 장애 기록(증상, 원인, 복구, 재발 방지)
- `evidence/` : 검증 결과 및 스크린샷/출력 캡처
- `decisions/` : 의사결정 기록(왜 이렇게 설계했는지)
- `diary/` : 일일 기록(진행 로그)



## 링크

- Runbook 목차: `runbook/index.md`

