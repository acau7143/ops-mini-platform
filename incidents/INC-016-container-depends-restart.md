# INC-016 — 컨테이너 기동 순서 오류 및 restart policy 실험

## Summary

`depends_on` 제거 시 `nginx-proxy` 컨테이너가 `app` 컨테이너보다 먼저 기동을 시도하면서 Docker 내부 DNS 조회 실패로 nginx가 반복 재시작되는 현상을 재현했다. 또한 `restart: unless-stopped` 와 `restart: no` 설정에서 컨테이너 재시작 동작 차이를 직접 확인했다.

## Severity

Low

## Impact

- `depends_on` 제거 시 `nginx-proxy` 가 반복 재시작되어 `localhost:8080` 접근 불가
- `restart: no` 설정 시 컨테이너 내부 프로세스 종료 후 수동 재시작 필요

## 시나리오 1 — depends_on 제거

### Detection

```bash
sudo docker ps
# STATUS: Restarting (1) N seconds ago 반복 확인

curl -I http://localhost:8080
# curl: (7) Failed to connect to localhost port 8080
```

### Timeline

1. `docker-compose.yaml` 에서 `depends_on` 블록 제거
2. `docker compose down`
3. `docker compose up -d nginx` (nginx-proxy만 먼저 기동)
4. `docker ps` 에서 `Restarting (1)` 반복 확인
5. `curl -I http://localhost:8080` 실패 확인
6. `docker-compose.yaml.bak` 으로 원복
7. `docker compose up -d` 후 정상 복구 확인

### Root Cause

`nginx-proxy` 컨테이너의 `default.conf` 에 `proxy_pass http://app/` 설정이 있다. nginx는 시작 시 이 설정을 읽으면서 `app` 이라는 호스트명을 Docker 내부 DNS로 조회한다. `app` 컨테이너가 없으면 DNS 조회가 실패하고 nginx 프로세스가 비정상 종료된다. `restart: unless-stopped` 설정으로 인해 재시작을 반복하지만 매번 같은 이유로 실패한다.

```
nginx-proxy 시작
    ↓
default.conf 읽음 → proxy_pass http://app/
    ↓
Docker DNS: "app 컨테이너 없음"
    ↓
nginx 시작 실패 → Exited
    ↓
restart: unless-stopped → 재시작 시도
    ↓
반복
```

### Recovery

```bash
sudo docker compose down
cp docker-compose.yaml.bak docker-compose.yaml
sudo docker compose up -d
curl -I http://localhost:8080  # 200 OK 확인
```

---

## 시나리오 2 — restart policy 실험

### 실험 목적

컨테이너 내부 프로세스가 예상치 못하게 종료됐을 때 `restart` 설정에 따라 동작이 어떻게 달라지는지 확인한다.

### 실험 방법

```bash
# app 컨테이너 내부 nginx 프로세스 종료
sudo docker exec app nginx -s stop

# 상태 확인
sudo docker ps
```

### 결과

| restart 설정 | 내부 프로세스 종료 시 | docker kill 시 |
|---|---|---|
| `unless-stopped` | 자동 재시작 됨 | 재시작 안 됨 |
| `no` | 재시작 안 됨 | 재시작 안 됨 |

### 핵심 차이

- `docker kill` → Docker가 "사용자가 의도적으로 종료한 것"으로 판단 → 재시작 안 함
- 내부 프로세스 종료 → Docker가 "예상치 못한 종료"로 판단 → `unless-stopped` 면 재시작 함

### Recovery

```bash
sudo docker compose down
cp docker-compose.yaml.bak docker-compose.yaml
sudo docker compose up -d
curl -I http://localhost:8080  # 200 OK 확인
```

---

## Prevention

- `docker-compose.yaml` 에서 컨테이너 간 의존성이 있으면 반드시 `depends_on` 을 명시한다.
- `proxy_pass` 에 컨테이너 이름을 사용할 경우 해당 컨테이너가 먼저 떠 있어야 DNS 조회가 성공한다.
- 운영 환경에서는 `restart: unless-stopped` 를 기본으로 사용해 예상치 못한 종료 시 자동 복구되도록 설정한다.

## Evidence

- `sudo docker ps` 에서 `Restarting (1)` 반복 확인
- `curl: (7) Failed to connect to localhost port 8080` 확인
- `restart: unless-stopped` 에서 내부 프로세스 종료 후 자동 재시작 확인
- `restart: no` 에서 `Exited (137)` 상태로 멈춤 확인