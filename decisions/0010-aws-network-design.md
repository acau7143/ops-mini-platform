# Decision 0010 — AWS 네트워크 및 보안 설계 근거

## Context

EC2 기반 운영형 인프라 프로젝트를 진행하면서
VPC, 서브넷, Security Group, IAM Role 구성을 선택했다.
콘솔에서 만든 인프라가 왜 이런 구조인지 근거를 정리한다.

---

## VPC 구성

| 항목 | 값 | 비고 |
|------|-----|------|
| VPC CIDR | 172.31.0.0/16 | AWS Default VPC |
| 서브넷 | ap-northeast-2a/b/c/d | 각 AZ별 서브넷 자동 생성 |
| 서브넷 유형 | Public (Auto-assign Public IP 활성화) | 별도 Private 서브넷 미구성 |

### 선택 이유

AWS 계정 생성 시 자동으로 제공되는 Default VPC를 사용했다.
이번 프로젝트의 목적은 VPC 설계 자체보다
운영/장애대응/문서화 역량 증명이기 때문에
네트워크 구성 복잡도보다 실습 집중도를 우선했다.

### 알고 있는 한계

- Default VPC는 모든 서브넷이 Public으로 구성된다.
- 실무에서는 Public/Private 서브넷을 분리하고
  DB, 내부 서비스는 Private 서브넷에 배치하는 것이 일반적이다.
- 이번 프로젝트 범위에서는 단일 EC2 + 단일 Public 서브넷으로 충분하다고 판단했다.

### 실무 개선 방향

- VPC를 직접 설계할 경우: 10.0.0.0/16 대역 사용
- Public 서브넷: 10.0.1.0/24 (Nginx, Bastion)
- Private 서브넷: 10.0.2.0/24 (DB, 내부 앱)
- NAT Gateway를 통해 Private → 외부 통신 허용

---

## Security Group 설계

| 규칙 | 프로토콜 | 포트 | 소스 | 이유 |
|------|----------|------|------|------|
| HTTP | TCP | 80 | 0.0.0.0/0 | 외부 사용자 웹 접근 허용 |
| SSH | TCP | 22 | 0.0.0.0/0 | 원격 접속 (개선 필요) |

### 선택 이유

- HTTP 80 전체 허용: 외부에서 Nginx 접근을 검증하는 것이
  프로젝트 핵심 목표이므로 전체 허용이 필요했다.
- SSH 22 전체 허용: 개발/실습 환경 특성상 고정 IP가 없어
  특정 IP로 제한하기 어려운 상황이었다.

### 알고 있는 한계

- SSH를 0.0.0.0/0으로 열면 전 세계 어디서든 22포트로
  접속 시도가 가능하다. 브루트포스 공격 대상이 될 수 있다.
- 이를 보완하기 위해 Day4-5에서 PasswordAuthentication no를
  적용하여 키 기반 인증만 허용했다. (decisions/0002 참고)

### 실무 개선 방향

- SSH 소스를 내 고정 IP 또는 Bastion Host IP로 제한
- 예: 소스를 `X.X.X.X/32`로 변경
- Bastion Host 패턴: 외부 → Bastion(22) → 내부 EC2(22)

---

## IAM Role 설계

| 정책 | 유형 | 실제 필요 여부 |
|------|------|----------------|
| CloudWatchAgentServerPolicy | AWS 관리형 | 필요 (CloudWatch Agent 동작) |
| CloudWatchReadOnlyAccess | AWS 관리형 | 필요 (메트릭 조회) |
| AmazonEC2FullAccess | AWS 관리형 | 불필요 (실습 편의상 추가) |
| AmazonS3FullAccess | AWS 관리형 | 불필요 (실습 편의상 추가) |

### 선택 이유

CloudWatch Agent 동작과 Terraform 운영을 EC2 터미널에서 수행하기 때문에
하나의 IAM Role에 필요한 권한을 모두 부여했다.

### 알고 있는 한계

- EC2FullAccess, S3FullAccess는 실제 필요한 것보다 넓은 권한이다.
  Terraform이 실제로 사용하는 작업만 허용하는 커스텀 정책으로
  대체하는 것이 더 안전하다.
- EC2가 1대인 구조상 Role을 역할별로 분리하기 어려웠다.
  서버가 늘어나면 Terraform 전용 Role, Agent 전용 Role로
  분리해서 각 EC2에 붙이는 것이 맞다.
- Docker 컨테이너로 역할을 나눠도 EC2 IAM Role을 공유하므로
  컨테이너 단위 권한 분리는 ECS Task Role 또는 IRSA(EKS) 같은
  별도 방식이 필요하다.

### 실무 개선 방향

- CloudWatch Agent 전용 Role에는 아래만 부여
  - CloudWatchAgentServerPolicy
  - (필요 시) CloudWatchReadOnlyAccess
- EC2FullAccess, S3FullAccess는 즉시 제거
- 권한은 실제로 필요한 것만, 필요한 시점에 부여

---

## 최소 권한 원칙 (Least Privilege) 적용 현황

| 항목 | 현재 상태 | 실무 기준 | 개선 필요 |
|------|-----------|-----------|-----------|
| SSH 소스 | 0.0.0.0/0 | 특정 IP 제한 | Yes |
| IAM EC2Full | 부여됨 | 미부여 | Yes |
| IAM S3Full | 부여됨 | 미부여 | Yes |
| CloudWatch Policy | 부여됨 | 유지 | No |
| PasswordAuthentication | 비활성화 | 비활성화 | No |

---

## 결론

이번 프로젝트에서는 운영/장애대응/문서화 역량 증명을 우선 목표로 했기 때문에
네트워크 설계 복잡도는 최소화했다.
단, 각 선택의 한계와 실무 개선 방향을 인지하고 있으며
실제 운영 환경에서는 위 개선 방향을 적용할 것이다.