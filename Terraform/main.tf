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

resource "aws_key_pair" "key1" {
  key_name   = "key1"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCXDS3XX69+B/jqvdUCttM5gB6Cz4bmepYbFgoCuJinbB3FH1g+aiyzbAdlt1Qr7vkTXBzareWrlUPdWlwiQbcK+eQzakVmB607G+ztSyra5KLLF55aM5K/68XdGRpJW1IwLZ6KfLRB/OumT6wKo5k8Q+UKOlHE0rzQQHPJjHg7cWyqJYeMHMEY72sO8Qo/xNs3h+OHdRlVLL91JGGZZ4ybnFRw0SyHQ3yy1dDCqN9iHzDhLk1ERExpwVqct4tcM0NcKdpxKQ0CC0XQKXRWPdgZd4c0ry4FeKSvMParhz7mKAx6fYyQLwRsE0e/gut+A55mggdof5HqPiUj8QRP1tFF"
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
  key_name = "${aws_key_pair.key1.key_name}"
  vpc_security_group_ids = ["${aws_security_group.group1.id}"]
  subnet_id = "${var.subnet_id}"
  user_data = <<EOF
#!/bin/bash
#sudo apt update && sudo apt install -y openjdk-8-jdk maven awscli
#git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git
#cd boxfuse-sample-java-war-hello && mvn package
#export AWS_ACCESS_KEY_ID=<>
#export AWS_SECRET_ACCESS_KEY=<>
#export AWS_DEFAULT_REGION=us-east-2
#aws s3 cp target/hello-1.0.war s3://lession13
EOF

}

resource "aws_instance" "prod_instance" {
  ami = "${var.image_id}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.key1.key_name}"
  vpc_security_group_ids = ["${aws_security_group.group1.id}"]
  subnet_id = "${var.subnet_id}"
  user_data = <<EOF
#!/bin/bash
#sudo apt update && sudo apt install -y openjdk-8-jdk tomcat9 awscli
#export AWS_ACCESS_KEY_ID=<>
#export AWS_SECRET_ACCESS_KEY=<>
#export AWS_DEFAULT_REGION=us-east-2
#aws s3 cp s3://lession13/hello-1.0.war /tmp/hello-1.0.war
#sudo mv /tmp/hello-1.0.war /var/lib/tomcat9/webapps/hello-1.0.war
#sudo systemctl restart tomcat8
EOF

}

rresource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/inventory.tpl",
    {
      prod_ip = aws_instance.prod_instance.public_ip
      build_ip = aws_instance.build_instance.public_ip
    }
  )
  filename = "hosts.cfg"
}