# INC-003 — nginx config test fail



## Summary

Nginx 설정 파일에 의도적으로 문법 오류를 추가한 뒤 `sudo nginx -t` 검사 실패를 확인했다.

이후 백업 파일로 원복하고 다시 검사를 수행하여 정상 상태로 복구했다.



## Impact

- 잘못된 설정이 실제 서비스 reload 전에 차단되었다.

- 설정 변경 전 백업과 사전 문법 검사의 필요성을 확인했다.



## What changed

- `/etc/nginx/sites-available/default` 파일에 의도적인 문법 오류 1줄을 추가했다.



## Detection

다음 명령으로 설정 오류를 탐지했다.



```bash

sudo nginx -t

```

## Cause

Nginx 설정 파일에 nginx 문법에 맞지 않는 라인이 포함되었다.



## Recovery

- 기존 백업 파일로 설정을 원복했다.
- sudo nginx -t 를 다시 실행해 설정 정상 여부를 확인했다.
- sudo systemctl reload nginx 로 서비스를 정상 상태로 유지했다.



## Validation



```bash

sudo nginx -t 성공 확인
systemctl is-active nginx 확인
curl -I http://localhost 확인

```



## Prevention

- 설정 변경 전 반드시 백업 수행
- reload 전에 반드시 sudo nginx -t 수행
- 운영 문서에 nginx 설정 변경 절차를 고정

