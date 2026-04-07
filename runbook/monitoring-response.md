# monitoring-response.md

## 목적

CloudWatch 알람이 발생했을 때, 원인을 확인하고 조치한 뒤 기록까지 마무리하는 흐름을 정리한다.

---

## 알람 감지 방법

현재 구성 기준으로 알람은 아래 방법으로 확인한다.

- AWS 콘솔 → CloudWatch → Alarms 에서 상태 직접 확인

---

## 대응 기본 흐름

1. 알람 감지 — CloudWatch 콘솔에서 상태 확인
2. 현재 상태 확인 — 서버 접속 후 해당 지표 직접 확인
3. 원인 파악 — 프로세스, 로그, 컨테이너 상태 확인
4. 조치 — 원인에 따라 프로세스 종료 / 서비스 재시작
5. 복구 확인 — 지표가 정상 범위로 돌아왔는지 확인
6. 기록 — Diary 또는 INC 문서에 남긴다

---

## CPU 알람 (ops-mini-cpu-high)

### 알람 조건

- 지표: EC2 CPUUtilization
- 임계값: 80% 초과
- 평가 기간: 5분 1회

### 1단계 — 현재 CPU 사용률 확인
```bash
top
```

### 2단계 — CPU를 많이 쓰는 프로세스 확인
```bash
ps aux --sort=-%cpu | head -10
```

### 3단계 — 컨테이너 상태 확인
```bash
docker ps
docker stats --no-stream
```

### 4단계 — 조치

| 원인 | 조치 |
|------|------|
| 특정 프로세스 과부하 | 해당 프로세스 확인 후 필요 시 종료 |
| 컨테이너 과부하 | `docker restart <컨테이너명>` |
| 테스트용 부하 (stress 등) | `pkill stress` |

### 5단계 — 복구 확인
```bash
top
docker stats --no-stream
```

CPU 사용률이 80% 아래로 내려왔는지 확인한다.

---

## 메모리 알람 (ops-mini-mem-high)

### 알람 조건

- 지표: mem_used_percent (CloudWatch Agent 수집)
- 임계값: 80% 초과
- 평가 기간: 5분 1회

### 1단계 — 현재 메모리 사용률 확인
```bash
free -h
```

### 2단계 — 메모리를 많이 쓰는 프로세스 확인
```bash
ps aux --sort=-%mem | head -10
```

### 3단계 — 컨테이너 메모리 확인
```bash
docker stats --no-stream
```

### 4단계 — 조치

| 원인 | 조치 |
|------|------|
| 특정 프로세스 메모리 과다 | 프로세스 재시작 또는 종료 |
| 컨테이너 메모리 과다 | `docker restart <컨테이너명>` |
| 시스템 캐시 과다 | 자동 해소 대기 후 모니터링 유지 |

### 5단계 — 복구 확인
```bash
free -h
```

사용 중인 메모리가 80% 아래로 내려왔는지 확인한다.

---

## 알람 상태 확인 명령어
```bash
aws cloudwatch describe-alarms \
  --query 'MetricAlarms[*].{Name:AlarmName,State:StateValue}' \
  --output table
```

---

## 기록 기준

| 상황 | 기록 방법 |
|------|-----------|
| 테스트로 트리거한 경우 | Diary에 기록 |
| 실제 원인 불명 알람 | INC 문서 작성 |
| 반복 발생 | INC + Prevention 항목 보강 |