\# Access (Day1)



\## 인스턴스 기본

\- OS: Ubuntu 22.04 LTS (예정/사용)

\- SSH 사용자: ubuntu

\- Security Group Inbound (Day1 기준)

&nbsp; - 22/tcp: 내 IP

&nbsp; - 80/tcp: 실습용(필요 시 전체 허용)



\## Nginx 상태 확인/검증

```bash

sudo systemctl status nginx --no-pager

curl -I http://localhost

