provider "aws" {
  region = "us-east-2"
}

variable "subnet_id" {
  default = "subnet-2303f85e"
}

variable "vpc_id" {
  default = "vpc-374d285c"
}
variable "image_id" {
  default = "ami-00399ec92321828f5"
}

resource "tls_private_key" "key" {
 algorithm = "RSA"
 rsa_bits  = 4096
}

resource "aws_key_pair" "aws_key" {
 key_name   = "aws-ssh-key"
 public_key = tls_private_key.key.public_key_openssh
}


resource "aws_security_group" "group1" {
  name        = "group1"
  vpc_id      = "${var.vpc_id}"

  ingress {
    description = "app from anywhere"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
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

resource "aws_instance" "build_instance" {
  ami = "${var.image_id}"
  instance_type = "t2.micro"
  key_name = aws_key_pair.aws_key.key_name
  vpc_security_group_ids = ["${aws_security_group.group1.id}"]
  subnet_id = "${var.subnet_id}"
  user_data = <<EOF
#!/bin/bash
sudo apt update && sudo apt install -y docker.io python
EOF
}

resource "aws_instance" "prod_instance" {
  ami = "${var.image_id}"
  instance_type = "t2.micro"
  key_name = aws_key_pair.aws_key.key_name
  vpc_security_group_ids = ["${aws_security_group.group1.id}"]
  subnet_id = "${var.subnet_id}"
  user_data = <<EOF
#!/bin/bash
sudo apt update && sudo apt install -y docker.io python
EOF
}


resource "local_file" "private_key" {
  sensitive_content = tls_private_key.key.private_key_pem
  filename          = format("%s/%s/%s", abspath(path.root), ".ssh", "aws-ssh-key.pem")
  file_permission   = "0600"
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl",
    {
      prod_ip = aws_instance.prod_instance.public_ip
      build_ip = aws_instance.build_instance.public_ip
      ssh_keyfile = local_file.private_key.filename
    }
  )
  format("%s/%s", abspath(path.root), "inventory.yaml")
}