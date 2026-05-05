# Decision 0007 — Terraform 변수 구조화

## Context
main.tf에 AMI ID, 인스턴스 타입, 키 이름이 하드코딩되어 있었다.
값을 바꾸려면 main.tf를 직접 수정해야 했고, 재사용이 어려운 구조였다.

## Decision
variables.tf, terraform.tfvars, outputs.tf를 분리하여 변수 구조화를 적용했다.

## Why
- 값 변경 시 terraform.tfvars 한 파일만 수정하면 전체에 반영된다
- main.tf는 구조만 정의하고, 실제 값은 tfvars에서 관리한다
- outputs.tf로 apply 후 Public IP를 터미널에서 바로 확인할 수 있다

## 대안과의 비교
| 방식 | 장점 | 단점 |
|------|------|------|
| 하드코딩 | 단순함 | 값 바꿀 때마다 main.tf 수정 필요 |
| variables.tf + tfvars | 재사용성, 관리 편의 | 파일이 늘어남 |
| 환경변수(TF_VAR_) | 파일 없이 관리 가능 | 추적이 어렵고 GitHub에 남길 수 없음 |

## Result
terraform validate, terraform plan 모두 정상 확인.
변수값이 tfvars에서 올바르게 읽혀오는 것을 plan 출력으로 검증했다.