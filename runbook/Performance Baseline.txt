# Performance Baseline

## 목적

서버와 앱 컨테이너의 정상 상태 성능 수치를 기록해두고,
설정 변경 또는 장애 후 재측정 시 비교 기준으로 사용한다.

## 측정 도구

- `ab` (Apache Benchmark) — `apache2-utils` 패키지에 포함

## 측정 방법

```bash
ab -n 1000 -c 10 http://localhost:8080/
```

- `-n 1000` : 총 요청 수
- `-c 10` : 동시 요청 수

## 기준선 수치 (2026-04-11 측정)

| 항목 | 수치 |
|------|------|
| Requests per second | 3068 req/sec |
| 평균 응답시간 | 3ms |
| 최대 응답시간 | 16ms |
| Failed requests | 0 |
| 측정 환경 | AWS EC2, nginx-proxy 컨테이너, 요청 1000개 동시 10개 |

## 재측정 시점

- nginx 설정 변경 후
- docker-compose.yml 구조 변경 후
- 인스턴스 타입 변경 후
- 성능 저하 의심 시

## 판단 기준

- Requests per second가 기준선 대비 **20% 이상 감소** 시 원인 확인
- Failed requests가 **1개 이상** 발생 시 즉시 확인
- 평균 응답시간이 **10ms 초과** 시 확인

## 결과 저장 위치

- `evidence/day24-ab-baseline.txt`