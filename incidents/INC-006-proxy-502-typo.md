# INC-006-Nginx Reverse Proxy 502 (Wrong Upstream Port)

## Summary

Nginx에 `/app` reverse proxy를 추가하는 과정에서 `proxy_pass` 의 upstream 포트를 실제 Docker 앱 포트와 다르게 설정하여 `502 Bad Gateway`가 발생했다. Nginx 자체는 정상 동작했지만 `/app` 요청이 백엔드 앱으로 전달되지 않았고, `error.log` 확인 후 정상 포트로 수정하여 복구했다.

## Severity

Low

## Impact

호스트 nginx 서비스 자체에는 큰 영향이 없었지만, `/app` 경로를 통한 Docker 앱 접근이 불가능했다.  
즉 Day10의 목표인 Nginx ↔ Docker 앱 연결 상태가 성립하지 않았고, 외부/public IP 기준 `/app` 접근도 실패했다.

## Detection

아래 명령으로 문제를 확인했다.

```bash
curl -I http://localhost/app
curl -I http://<PUBLIC_IP>/app
curl http://localhost:8080
sudo tail -n 20 /var/log/nginx/error.log
sudo nginx -t
```

curl -I http://localhost/app 및 curl -I http://<PUBLIC_IP>/app 요청에서 502 Bad Gateway 가 확인되었다.
반면 curl http://localhost:8080 은 정상 응답하여 Docker 앱 자체는 살아 있었고, 문제 지점이 Nginx reverse proxy 설정 쪽임을 확인했다.

## Timeline

- Docker 앱이 localhost:8080 에서 정상 응답하는지 확인
- /etc/nginx/sites-available/default 파일에 /app reverse proxy 설정 추가
- proxy_pass 값을 일부러 잘못된 upstream 포트로 설정
- sudo nginx -t 로 문법 확인
- sudo systemctl reload nginx
- curl -I http://localhost/app 실행
- curl -I http://<PUBLIC_IP>/app 실행
- 502 Bad Gateway 재현
- sudo tail -n 20 /var/log/nginx/error.log 로 upstream 연결 실패 메시지 확인
- proxy_pass 를 정상값으로 수정
- sudo nginx -t 후 reload
- /app 정상 응답 확인

## Symptoms

- /app 요청 시 502 Bad Gateway 발생
- Nginx 서비스 자체는 active 상태 유지
- Docker 앱은 localhost:8080 에서 정상 응답

즉, 앱이 죽은 것이 아니라 Nginx가 upstream 연결에 실패한 상태였음

## Root Cause

- Nginx reverse proxy 설정의 proxy_pass 값이 실제 Docker 앱이 열려 있는 주소/포트와 일치하지 않았다.
- 그 결과 /app 요청이 백엔드 컨테이너로 전달되지 못했고 Nginx가 upstream 연결 실패를 502 Bad Gateway 로 반환했다.
- 대표적으로 error.log 에서 아래와 같은 메시지를 확인할 수 있었다.
- connect() failed (111: Connection refused) while connecting to upstream

## Recovery

- 잘못 입력한 proxy_pass 값을 정상 upstream 으로 수정한 뒤 Nginx를 reload 했다.

``` bash
예시:

sudo nginx -t
sudo systemctl reload nginx

복구 후 아래 명령으로 재검증했다.

curl -I http://localhost/app
curl -I http://<PUBLIC_IP>/app
curl http://localhost/app
curl http://localhost:8080
sudo tail -n 20 /var/log/nginx/error.log

검증 결과:

curl -I http://localhost/app 에서 정상 HTTP 응답 확인

curl -I http://<PUBLIC_IP>/app 에서 정상 HTTP 응답 확인

curl http://localhost:8080 정상 응답 유지

reverse proxy 복구 후 /app 경로가 정상 동작함을 확인
```

## Prevention

- reverse proxy 연결 전 백엔드 앱 직접 응답(curl http://localhost:8080)을 먼저 확인한다.
- proxy_pass 의 IP/포트를 실제 실행 중인 서비스와 대조한다.
- 설정 변경 후 반드시 sudo nginx -t 를 먼저 수행한다.
- 502 발생 시 앱 자체 문제인지, reverse proxy 문제인지 분리해서 본다.
- error.log 를 먼저 확인하는 절차를 runbook에 반영한다.

## Evidence

![image.png](../evidence/day10-502-error-log.png)

![image.png](../evidence/day10-app-ok.png)
