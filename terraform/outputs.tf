output "instance_public_ip" {
    description = "EC2 인스턴스의 Public IP"
    value       = aws_instance.ops_mini.public_ip
}
