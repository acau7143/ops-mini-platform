# INC-015 — 배포 실패 및 자동 롤백 트리거

## Summary

`deploy.sh` 실행 중 헬스체크 대상 포트를 존재하지 않는 포트(9999)로 설정하여 헬스체크 3회 실패를 재현했다. `healthcheck()` 함수가 `return 1` 을 반환하면서 `rollback()` 이 자동으로 트리거되었고 이전 이미지로 컨테이너가 재기동되었다.

## Severity

Low

## Impact

- 배포 실패 상황에서 수동 개입 없이 자동 롤백이 동작함을 확인했다
- 롤백 완료 후 컨테이너는 이전 정상 상태로 복구되었다

## Detection

```bash
cat evidence/2026-05-14_22:12:47-deploy/deploy.log
```

```
[2026-05-14 22:12:58]  롤백 시작
[2026-05-14 22:12:58]  롤백 완료
```

## Timeline

1. `SERVICE_URL` 을 `http://localhost:9999` 로 변경
2. `./scripts/deploy.sh` 실행
3. `docker compose pull` → 이미지 최신화
4. `docker compose up -d` → 컨테이너 기동
5. `healthcheck()` 3회 시도 → 모두 실패
6. `return 1` 반환 → `rollback()` 자동 트리거
7. `docker compose down` → 컨테이너 중지
8. `docker compose up -d --no-pull` → 이전 이미지로 재기동
9. `SERVICE_URL` 을 `http://localhost:8080` 으로 원복
10. `./scripts/deploy.sh` 재실행 → 정상 배포 확인

## Symptoms

- 헬스체크 3회 모두 실패
- `deploy.sh` 가 `exit 1` 로 종료
- `deploy.log` 에 롤백 시작/완료 로그 기록

## Root Cause

`SERVICE_URL` 이 실제 서비스가 없는 포트(9999)를 가리키고 있었다.  
`curl -sf` 가 연결에 실패하면서 `healthcheck()` 가 `return 1` 을 반환했고, 메인 흐름의 `if healthcheck` 분기가 `else` 로 진입하여 `rollback()` 이 실행되었다.

## Recovery

```bash
# SERVICE_URL 원복
vim scripts/deploy.sh
# SERVICE_URL="http://localhost:8080" 으로 수정

# 정상 배포 재실행
./scripts/deploy.sh
```

## Validation After Recovery

```bash
cat evidence/{timestamp}-deploy/after.txt
# 컨테이너 정상 기동 확인

curl -I http://localhost:8080
# HTTP 200 OK 확인
```

## Prevention

- 배포 전 `SERVICE_URL` 과 실제 서비스 포트가 일치하는지 확인한다
- `deploy.log` 를 항상 확인하여 롤백 여부를 파악한다
- 헬스체크 실패 시 `docker ps` 로 컨테이너 상태를 추가 확인한다

## Evidence

- `evidence/2026-05-14_22:12:47-deploy/deploy.log`
- `evidence/2026-05-14_22:12:47-deploy/before.txt`