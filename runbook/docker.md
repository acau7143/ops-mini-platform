# Docker



## 목적

Docker 서비스의 상태 확인, 중지, 시작, 복구 절차를 간단히 정리한다.



## 상태 확인

```bash
systemctl is-active docker
systemctl is-active docker.socket
docker version
sudo docker ps
```



## 중지

``` bash
sudo systemctl stop docker
sudo systemctl stop docker.socket
```

## 시작
```bash
sudo systemctl start docker
sudo systemctl start docker.socket
```



## 복구 확인
```bash
systemctl is-active docker
systemctl is-active docker.socket
sudo docker ps
sudo docker run hello-world
```



## 주의사항
- docker.service만 중지하면 docker.socket 이 남아 있을 수 있다.
- Docker 장애 재현 시 service와 socket을 함께 확인한다.
- docker ps 실패 여부로 daemon 연결 상태를 확인할 수 있다.

