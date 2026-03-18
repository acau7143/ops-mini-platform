
# Nginx

## 설정 파일
- `/etc/nginx/sites-available/default`

## 기본 검증
```bash
sudo nginx -t
sudo systemctl status nginx
curl -I http://localhost
```
## /app Reverse Proxy

/app 요청을 Docker 앱(127.0.0.1:8080)으로 전달한다.

```bash
location = /app {
    proxy_pass http://127.0.0.1:8080/;
}

location /app/ {
    proxy_pass http://127.0.0.1:8080/;
}
```

## 적용 절차
```bash
sudo nginx -t
sudo systemctl reload nginx
curl http://localhost/app
curl http://<PUBLIC_IP>/app
502 체크
curl http://localhost:8080
sudo docker ps
sudo tail -n 20 /var/log/nginx/error.log
```
- 앱이 직접 응답하는지 확인
- proxy_pass 주소/포트 확인
- nginx -t 후 reload
- error.log 에 upstream 에러 확인



## 502
```bash
curl http://localhost:8080
sudo docker ps
sudo tail -n 20 /var/log/nginx/error.log
```