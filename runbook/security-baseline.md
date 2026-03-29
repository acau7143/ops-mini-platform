# Security Baseline

## Purpose

서버의 기본 보안 상태를 같은 기준으로 점검한다.
설정 변경 전후, 또는 정기 점검 시 이 문서를 기준으로 사용한다.

## 점검 항목

### 1. SSH 설정
```bash
sudo grep -E "^PasswordAuthentication|^PermitRootLogin" /etc/ssh/sshd_config
```

| 항목 | 기대값 | 이유 |
|------|--------|------|
| PasswordAuthentication | no | 비밀번호 로그인 차단, 키 기반 인증만 허용 |
| PermitRootLogin | no | root 직접 접속 차단 |

### 2. UFW 상태 및 허용 포트
```bash
sudo ufw status verbose
```

| 항목 | 기대값 |
|------|--------|
| Status | active |
| Default incoming | deny |
| Default outgoing | allow |
| 허용 포트 | 22/tcp, 80/tcp |

### 3. 파일 권한
```bash
ls -la /etc/ssh/sshd_config
ls -la /etc/nginx/sites-available/default
```

| 파일 | 기대 권한 | 기대 소유자 |
|------|-----------|-------------|
| /etc/ssh/sshd_config | 644 | root |
| /etc/nginx/sites-available/default | 644 | root |

### 4. Nginx 보안 헤더
```bash
curl -sI http://localhost | grep -iE "x-frame|x-content|x-xss|strict-transport|server"
```

| 헤더 | 기대값 | 현재 상태 |
|------|--------|-----------|
| X-Frame-Options | SAMEORIGIN | 미적용 |
| X-Content-Type-Options | nosniff | 미적용 |
| Server | 버전 비노출 | nginx/1.24.0 노출 중 |

> Day18에서 보안 헤더 적용 예정

## Normal Expectations

- SSH는 키 기반 인증만 허용된 상태
- UFW가 active 상태이며 22/80 포트만 허용
- 주요 설정 파일은 root 소유, 644 권한
- Nginx 보안 헤더는 Day18 이후 적용 예정

## 비정상 판단 기준

| 증상 | 의심 원인 |
|------|-----------|
| UFW Status: inactive | UFW 비활성화 상태 → 즉시 재활성화 필요 |
| PasswordAuthentication yes | 비밀번호 로그인 허용 상태 → 변경 필요 |
| 설정 파일 권한이 777 또는 666 | 과도한 권한 부여 → 즉시 수정 필요 |
| 외부에서 22번 외 포트 접근 가능 | UFW 규칙 누락 |