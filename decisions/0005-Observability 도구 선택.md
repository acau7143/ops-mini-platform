# Decision 0005-Observability 도구 선택

## Context

Week 4부터 서버 상태를 외부에서 모니터링하는 구조가 필요해졌다.
EC2 기반 운영 환경에서 별도 도구 없이 수동 점검만으로는
장애를 사전에 감지하기 어렵다는 판단이 있었다.

## Decision

1차 Observability 도구로 AWS CloudWatch를 선택한다.
EC2 CPU 사용률 알람 1개를 시작으로 모니터링 범위를 점진적으로 확장한다.

## Why

- EC2 인스턴스와 같은 AWS 환경에서 별도 설치 없이 바로 연동 가능하다.
- CPUUtilization 같은 기본 지표는 에이전트 없이도 수집된다.
- 알람 조건, 임계값, 대응 절차를 문서로 남기기 쉽다.
- 추후 SNS 연동, 로그 수집(CloudWatch Logs)으로 확장 가능하다.

## 알람 설정 기준

| 항목 | 값 |
|---|---|
| 지표 | CPUUtilization |
| 조건 | > 80% |
| 기간 | 5분 1회 |
| 알람명 | ops-mini-cpu-high |
| 액션 | 없음 (1차) |

## 제외한 선택지

- Prometheus + Grafana: 별도 설치와 운영 부담이 크다. 현재 단계에서는 과하다.
- Datadog: 유료 플랜 필요. 포트폴리오 단계에서는 불필요하다.

## 향후 확장 계획

- SNS 이메일 알람 연동
- CloudWatch Logs로 nginx 로그 수집
- 메모리/디스크 지표 추가 (CloudWatch Agent 설치 필요)