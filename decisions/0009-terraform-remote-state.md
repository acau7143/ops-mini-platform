# Decision 0009 — Terraform Remote State (S3 Backend)

## Context
Terraform state 파일이 로컬에만 존재하면
서버가 초기화되거나 팀 환경에서 협업할 때 state를 잃을 위험이 있다.

## Decision
S3 버킷을 Terraform backend로 사용해 state를 원격 저장한다.

## Why
- 로컬 state는 EC2가 날아가면 같이 사라진다
- 팀 환경에서 remote state가 없으면 각자 다른 state를 갖게 되어
  리소스 충돌이 발생할 수 있다
- 이미 AWS를 사용 중이므로 S3가 가장 자연스러운 선택이다

## 대안과의 비교

| 방식 | 장점 | 단점 |
|------|------|------|
| 로컬 저장 | 설정 불필요 | 유실 위험, 협업 불가 |
| S3 Backend | AWS 네이티브, 간단한 설정 | 버킷 사전 생성 필요 |
| Terraform Cloud | UI 제공, 잠금 기능 내장 | 별도 서비스 가입 필요 |

## Result
backend.tf로 S3 백엔드를 설정하고
state가 S3에 정상 저장되는 것을 확인했다.