# Decision 0007 — Terraform 도입

## Context

Day 1부터 Day 24까지 EC2, 보안그룹 등 AWS 인프라를 콘솔에서 직접 클릭해서 만들었다.
콘솔에서 만든 설정은 어디에도 남지 않아서 재현이 불가능하고 GitHub에 올릴 수도 없었다.
Day 25부터 인프라를 코드로 관리하기 위해 Terraform을 도입한다.

## Decision

인프라 관리 도구로 Terraform을 선택한다.

## Why

- 콘솔에서 클릭해서 만든 설정은 실행 후 사라지고 GitHub에 올릴 수 없다.
- `.tf` 파일로 정의하면 파일이 남으니까 GitHub에 올릴 수 있고 언제든 재현 가능하다.
- Docker Compose가 컨테이너 인프라를 파일로 관리하는 것처럼,
  Terraform은 AWS 인프라를 파일로 관리한다. IaC 개념의 확장이다.

## 대안과의 비교

| 도구 | 특징 | 한계 |
|------|------|------|
| AWS CloudFormation | AWS 자체 IaC 도구 | AWS에서만 사용 가능 |
| Terraform | HashiCorp에서 만든 IaC 도구 | AWS, GCP, Azure 모두 사용 가능 |

AWS CloudFormation도 대안이었지만 AWS에서만 쓸 수 있다.
Terraform은 AWS, GCP, Azure 모두 쓸 수 있어서 범용성 때문에 선택했다.
회사마다 쓰는 클라우드가 다를 수 있으므로 범용 도구를 배워두는 것이 취업 준비에 유리하다.

## 오늘 한 것

- `terraform/provider.tf` 작성 — AWS provider, ap-northeast-2 리전 설정
- `terraform/main.tf` 작성 — EC2 인스턴스 + 보안그룹(22, 80) 정의
- `terraform init` — AWS provider 플러그인(v5.100.0) 다운로드 완료
- `terraform plan` — EC2 1개 + 보안그룹 1개, 총 2개 생성 예정 확인

## plan 출력 읽는 법

```
Plan: 2 to add, 0 to change, 0 to destroy.
```

- `+` → 새로 만들 것
- `~` → 수정할 것
- `-` → 삭제할 것

오늘은 2개를 새로 만드는 plan이 나왔고 apply는 하지 않았다.

## 면접 한 줄 설명

"Terraform을 선택한 이유는 콘솔에서 만든 설정은 남지 않지만
.tf 파일로 관리하면 GitHub에 올리고 재현할 수 있기 때문입니다.
CloudFormation도 대안이었지만 AWS에서만 쓸 수 있는 반면
Terraform은 AWS, GCP, Azure 모두 쓸 수 있어서 선택했습니다."