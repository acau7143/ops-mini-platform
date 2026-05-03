resource "aws_security_group" "ops_mini_sg" {
  name        = "ops-mini-sg"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ops_mini" {
  ami                    = "ami-0130d8d35bcd2d433"
  instance_type          = "t2.micro"
  key_name               = "ops-mini-platform"
  vpc_security_group_ids = [aws_security_group.ops_mini_sg.id]

  tags = {
    Name = "ops-mini-platform"
  }
}