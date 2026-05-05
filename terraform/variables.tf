variable "ami_id" {
    description = "EC2에 사용할 AMI ID"
    type 	= string
}

variable "instance_type" {
    description = "EC2 인스턴스 타입"
    type        = string
    default     = "t3.micro"
}

variable "key_name" {
    description = "EC2에 연결할 키페어 이름"
    type        = string
}
