resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "SSH inbound traffic"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "SSH from owner IP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.myip]
  }
}