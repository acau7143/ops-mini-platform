# INC-008 — docker logs 수집 실패 (컨테이너 없음)

## Summary
log_snapshot.sh 실행 또는 docker logs 명령 수행 시
test-app 컨테이너가 없는 상태여서 로그 수집에 실패했다.

## Severity
Low

## Impact
- 장애 발생 시 앱 로그 수집 불가
- log_snapshot.sh 실행 시 docker logs 항목 누락

## Detection
```bash
docker logs test-app
# Error response from daemon: No such container: test-app
```

## Timeline
1. test-app 컨테이너 삭제
2. docker logs test-app 실행 → 실패 확인
3. docker run -d --name test-app -p 8080:80 nginx 로 복구
4. docker logs test-app → 정상 출력 확인

## Symptoms
- `No such container: test-app` 메시지 출력
- log_snapshot.sh의 docker logs 항목 수집 안 됨

## Root Cause
컨테이너가 없거나 중지된 상태에서
docker logs 를 실행하면 대상 컨테이너를 찾지 못해 실패한다.

## Recovery
```bash
docker run -d --name test-app -p 8080:80 nginx
docker logs test-app
```

## Prevention
- log_snapshot.sh에 컨테이너 없을 때 경고만 출력하고
  스크립트가 죽지 않도록 || echo "[WARN]..." 처리
- baseline-check에 docker ps 항목 유지

## Evidence
- evidence/day12-docker-logs-fail.png
![image.png](../evidence/day12-docker-logs-fail.png)
- evidence/day12-docker-logs-recover.png
![image.png](../evidence/day12-docker-logs-recover.png)