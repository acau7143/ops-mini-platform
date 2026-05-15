# deploy.md — 배포 절차

## 목적

Nginx 설정 변경 또는 Docker 앱 업데이트 시 안전하게 반영하는 표준 절차를 정의한다.

---

## 사전 조건

- [ ] 현재 서버 상태가 정상인지 baseline check 완료
- [ ] 변경할 설정 파일 백업 완료
- [ ] 변경 내용이 무엇인지 명확히 인지

---

## Nginx 설정 변경 배포 절차

### 1. 현재 상태 확인
```bash
systemctl is-active nginx
curl -I http://localhost
```

### 2. 설정 파일 백업
```bash
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak.$(date +%F)
```

### 3. 설정 변경
```bash
sudo vim /etc/nginx/sites-available/default
```

### 4. 문법 검증 (반드시 수행)
```bash
sudo nginx -t
```

- 실패 시 → 절대 reload 하지 말고 rollback.md 참고

### 5. 서비스 반영
```bash
sudo systemctl reload nginx
```

### 6. 배포 후 검증
```bash
curl -I http://localhost
curl -I http://localhost/app
sudo tail -n 20 /var/log/nginx/error.log
```

---

## Docker 앱 업데이트 배포 절차

### 1. 기존 컨테이너 상태 확인
```bash
sudo docker ps
curl -I http://localhost:8080
```

### 2. 새 컨테이너 실행 (교체)
```bash
sudo docker rm -f test-app
sudo docker run -d --name test-app -p 8080:80 nginx
```

### 3. 배포 후 검증
```bash
sudo docker ps
curl -I http://localhost:8080
curl -I http://localhost/app
```

---

## 자동 배포 (deploy.sh)

`scripts/deploy.sh` 를 사용하면 pull → up → 헬스체크 → 실패 시 롤백까지 자동으로 처리한다.

### 사전 확인

```bash
systemctl is-active docker
systemctl is-active docker.socket
docker ps
curl -I http://localhost:8080
```

### 실행

```bash
./scripts/deploy.sh
```

스크립트 내부 흐름:

| 순서 | 내용 |
|------|------|
| 1 | `evidence/{timestamp}-deploy/` 디렉토리 생성 |
| 2 | 현재 컨테이너 상태 → `before.txt` 저장 |
| 3 | `docker compose pull` — 최신 이미지 수신 |
| 4 | `docker compose up -d` — 컨테이너 재기동 |
| 5 | `healthcheck()` — `localhost:8080` 에 3회 응답 확인 |
| 6 | 성공 시 → `after.txt` 저장, `exit 0` |
| 7 | 실패 시 → `rollback()` 실행, `exit 1` |

### 결과 확인

```bash
# before/after 비교
cat evidence/{timestamp}-deploy/before.txt
cat evidence/{timestamp}-deploy/after.txt

# 롤백 여부 확인
cat evidence/{timestamp}-deploy/deploy.log
```

### 실패 시 대응

```bash
# deploy.log 에서 롤백 여부 확인
cat evidence/{timestamp}-deploy/deploy.log

# 컨테이너 상태 확인
docker ps
curl -I http://localhost:8080
```

---

## 중요 원칙

| 원칙 | 이유 |
|---|---|
| 변경 전 반드시 백업 | 빠른 rollback을 위해 |
| reload 전 nginx -t 필수 | 문법 오류로 서비스 중단 방지 |
| 배포 후 curl 검증 필수 | 변경이 실제 반영됐는지 확인 |
| error.log 확인 | 502 등 silent 장애 감지 |
| deploy.sh 사용 시 deploy.log 확인 | 롤백 여부 파악 |