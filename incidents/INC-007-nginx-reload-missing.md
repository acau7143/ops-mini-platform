# INC-007 — Nginx 설정 변경 후 reload 누락

## Summary

Nginx 설정을 변경한 뒤 `nginx -t`만 실행하고 `systemctl reload nginx`를 수행하지 않아
변경 내용이 실제 서비스에 반영되지 않은 상황을 재현했다.

## Severity

Low

## Impact

- 설정 변경이 반영됐다고 판단했지만 실제로는 이전 설정이 동작 중이었다.
- 이 상태에서 추가 변경이 발생하면 의도치 않은 설정이 누적될 수 있다.

## Detection
```bash
sudo nginx -T | grep -A5 "location /app"
# → 실행 중인 nginx 설정과 파일 내용이 다름을 확인
curl -I http://localhost/app
# → 파일 변경 전후 응답이 동일 (reload 누락으로 반영 안 됨)
```

## Root Cause

`nginx -t`는 설정 파일 문법 검사만 수행한다.  
실제 nginx 프로세스에 변경을 반영하려면 반드시 `systemctl reload nginx`를 수행해야 한다.  
reload를 생략하면 변경 전 설정이 메모리에 그대로 남아 동작한다.

## Recovery
```bash
sudo systemctl reload nginx
curl -I http://localhost
curl -I http://localhost/app
```

## Prevention

- deploy.md에 `nginx -t` → `systemctl reload nginx` → `curl 검증` 순서를 고정한다.
- reload 없이 배포를 완료한 것으로 착각하지 않도록 체크리스트를 유지한다.

## Evidence

- `nginx -T` 출력으로 실제 동작 설정 확인
	- 실패
![image.png](../evidence/day11-nginx-t-fail.png)
	- 성공
![image.png](../evidence/day11-nginx-t-ok.png)