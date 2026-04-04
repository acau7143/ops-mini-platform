# INC-011-Docker Compose 멀티 컨테이너 부분 장애

## Summary

Docker Compose로 nginx 컨테이너와 app 컨테이너를 분리한 멀티 컨테이너 구조에서
app 컨테이너만 중지했을 때 nginx 컨테이너가 502 Bad Gateway를 반환하는 상황을 재현했다.
`docker compose start app` 으로 복구 후 정상 응답을 확인했다.

## Severity

Low

## Impact

- `http://localhost:8080/app/` 접근 불가
- nginx 컨테이너 자체는 정상 동작
- 80포트 호스트 nginx는 영향 없음

## Detection
```bash
sudo docker compose stop app
curl -I http://localhost:8080/app/
sudo docker ps -a
```

## Timeline

- docker compose로 멀티 컨테이너 구조 전환 완료
- app 컨테이너 정상 동작 확인
- sudo docker compose stop app 으로 app 컨테이너 중지
- curl -I http://localhost:8080/app/ → 502 Bad Gateway 확인
- sudo docker ps -a 로 app 컨테이너 Exited 상태 확인
- sudo docker compose start app 으로 복구
- curl -I http://localhost:8080/app/ → 200 OK 확인

## Symptoms

- http://localhost:8080/app/ 요청 시 502 Bad Gateway 반환
- nginx 컨테이너는 Up 상태 유지
- app 컨테이너만 Exited 상태

## Root Cause

nginx 컨테이너가 `/app/` 요청을 compose 내부 네트워크의 app 컨테이너로
프록시하는 구조에서 app 컨테이너가 중지되어 upstream 연결에 실패했다.
nginx 컨테이너 자체는 살아있었지만 전달할 대상이 없어서 502를 반환했다.

## Recovery
```bash
sudo docker compose start app
curl -I http://localhost:8080/app/
```

## Prevention

- compose 구조에서는 개별 컨테이너 상태를 함께 모니터링해야 한다
- app 컨테이너 장애 시 nginx 502 로그를 먼저 확인한다
- healthcheck.sh에 멀티 컨테이너 상태 확인 항목 추가를 고려한다

## Evidence

![image.png](../evidence/day20-compose-multi-502-recover.png)