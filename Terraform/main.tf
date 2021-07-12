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

resource "aws_s3_bucket" "kmi" {
   bucket = "my-bucket-kmi"
   acl = "private"
   versioning {
    enabled = true
   }
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
    from_port   = 0
    to_port     = 0
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

resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ec2.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "ec2_s3-policy" {
  name        = "ec2_s3-policy"
  description = "A test policy"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
    {
      "Sid": "AccessObject",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket-kmi/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2_s3-attach" {
  role      = "${aws_iam_role.ec2_s3_role.name}"
  policy_arn = "${aws_iam_policy.ec2_s3-policy.arn}"
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name  = "ec2_s3_profile"
  role = "${aws_iam_role.ec2_s3_role.name}"
}

resource "aws_instance" "build_instance" {
  ami = "${var.image_id}"
  instance_type = "t2.micro"
  key_name = aws_key_pair.aws_key.key_name
  vpc_security_group_ids = ["${aws_security_group.group1.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ec2_s3_profile.name}"
  subnet_id = "${var.subnet_id}"
  user_data = <<EOF
#!/bin/bash
#sudo apt update && sudo apt install -y python
EOF
}

resource "aws_instance" "prod_instance" {
  ami = "${var.image_id}"
  instance_type = "t2.micro"
  key_name = aws_key_pair.aws_key.key_name
  vpc_security_group_ids = ["${aws_security_group.group1.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ec2_s3_profile.name}"
  subnet_id = "${var.subnet_id}"
  user_data = <<EOF
#!/bin/bash
#sudo apt update && sudo apt install -y python
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
   filename = format("%s/%s", abspath(path.root), "inventory.yaml")
}