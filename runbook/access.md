# Access

## SSH
서버 접속에 사용하는 기본 명령과 별칭.

## Server Info
- OS: Ubuntu
- Web Server: nginx
- Main service port: 80

## Important Paths
- nginx main config: /etc/nginx/nginx.conf
- nginx site config: /etc/nginx/sites-available/default
- project scripts: ~/ops-mini-platform/scripts
- evidence dir: ~/ops-mini-platform/evidence

## Log Paths
- nginx access log: /var/log/nginx/access.log
- nginx error log: /var/log/nginx/error.log

## Basic Validation Commands
``` bash
uptime
df -h
free -h
ss -lntp | grep -E ':80|:443'
systemctl is-active nginx
curl -I http://localhost
tail -n 20 /var/log/nginx/access.log
tail -n 20 /var/log/nginx/error.log
```

## Config Apply

nginx 설정 변경 후 항상 아래 순서로 반영한다.

``` bash
sudo nginx -t
sudo systemctl reload nginx
Useful Checks
sudo nginx -T
sudo grep -R "proxy_pass" /etc/nginx
./scripts/healthcheck.sh
./scripts/log_snapshot.sh
```
