# Access (Day1)



## 인스턴스 기본

- OS: Ubuntu 22.04 LTS (예정/사용)

- SSH 사용자: ubuntu

- Security Group Inbound (Day1 기준)

&nbsp; - 22/tcp: 내 IP

&nbsp; - 80/tcp: 실습용(필요 시 전체 허용)



## Nginx 상태 확인/검증

```bash

sudo systemctl status nginx --no-pager

curl -I http://localhost
```

# Access (Day2)

## 외부 HTTP 접근 확인

- 목적: EC2 내부(localhost)뿐 아니라 외부에서도 nginx 응답 확인
- 확인 대상
&nbsp; - nginx 서비스 상태
&nbsp; - localhost 응답
&nbsp; - Public IP 외부 응답
&nbsp; - UFW 상태

```bash
systemctl is-active nginx
curl -I http://localhost
ss -lntp | grep -E ':80|:443'
curl -I http://<EC2_PUBLIC_IP>
sudo ufw status verbose
```
## UFW 차단/복구 테스트

- 목적: HTTP(80) 차단 시 외부 접속 실패를 재현하고 복구

- 확인 포인트
&nbsp;- 외부 접속 실패 여부
&nbsp;- localhost는 계속 200 OK 인지
&nbsp;- 80/tcp 재허용 후 외부 복구 여부

```bash
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw enable
sudo ufw deny 80/tcp
sudo ufw status numbered
curl -I http://localhost
sudo ufw allow 80/tcp
sudo ufw status numbered
```
