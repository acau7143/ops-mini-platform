# rollback.md — 롤백 절차

## 목적

배포 후 장애가 발생했을 때 이전 상태로 빠르게 복구하는 절차를 정의한다.

---

## Nginx 설정 롤백

### 언제 사용하는가

- `nginx -t` 실패 시
- reload 후 502 / 404 등 이상 응답 발생 시
- error.log에 critical 에러 발생 시

### 절차
```bash
# 1. 백업 파일 확인
ls /etc/nginx/sites-available/

# 2. 백업으로 복구
sudo cp /etc/nginx/sites-available/default.bak.YYYY-MM-DD /etc/nginx/sites-available/default

# 3. 문법 재확인
sudo nginx -t

# 4. 서비스 반영
sudo systemctl reload nginx

# 5. 복구 검증
curl -I http://localhost
curl -I http://localhost/app
sudo tail -n 20 /var/log/nginx/error.log
```

---

## Docker 앱 롤백

### 언제 사용하는가

- 새 컨테이너 실행 후 HTTP 응답 실패 시
- 포트 매핑 오류로 접속 불가 시

### 절차
```bash
# 1. 현재 컨테이너 제거
sudo docker rm -f test-app

# 2. 이전 이미지 또는 올바른 설정으로 재실행
sudo docker run -d --name test-app -p 8080:80 nginx

# 3. 복구 검증
sudo docker ps
curl -I http://localhost:8080
```

---

## 롤백 후 필수 확인 항목
```bash
systemctl is-active nginx
curl -I http://localhost
curl -I http://localhost/app
curl -I http://localhost:8080
sudo tail -n 20 /var/log/nginx/error.log
sudo docker ps
```

---

## 원칙

- rollback은 신속성이 최우선이다. 원인 분석은 복구 후에 한다.
- 복구 후 반드시 INC 문서를 남긴다.
- 백업 없이 배포하면 rollback이 불가능할 수 있다.