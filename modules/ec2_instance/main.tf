resource "aws_instance" "host" {
  ami = var.ami
  instance_type = var.instance_type
  tags = var.tags
  key_name = var.ssh_key_name
  monitoring = var.monitoring_enabled
  associate_public_ip_address = var.associate_public_ip_address
  user_data = var.user_data
}