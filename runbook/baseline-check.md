# Baseline Check



## Purpose

매일 서버와 nginx의 기본 상태를 같은 기준으로 점검한다.



## Fixed Validation Commands

1\. 서버 업타임 확인

&nbsp;  - `uptime`



2. 디스크 사용량 확인

&nbsp;  - `df -h`



3. 메모리 상태 확인

&nbsp;  - `free -h`



4. 웹 포트 리슨 상태 확인

&nbsp;  - `ss -lntp | grep -E ':80|:443'`



5. nginx 서비스 상태 확인

&nbsp;  - `systemctl is-active nginx`



6. 로컬 HTTP 응답 확인

&nbsp;  - `curl -I http://localhost`



7. nginx access log 최근 20줄 확인

&nbsp;  - `tail -n 20 /var/log/nginx/access.log`



8. nginx error log 최근 20줄 확인

&nbsp;  - `tail -n 20 /var/log/nginx/error.log`



## Normal Expectations

- nginx is active

- localhost returns HTTP 200

- port 80 is listening

- disk and memory have enough headroom

- no critical errors in nginx error log

