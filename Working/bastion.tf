resource "aws_instance" "bastion" {
  ami           = "ami-02d26659fd82cf299" # Ubuntu 22.04 LTS (check for latest in your region)
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public[0].id
  key_name      = var.ssh_key_name

  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name = "${var.project}-${var.environment}-bastion"
  }
}
