variable "instance_type" {
  default = "t3.medium" # Recommended for K8s. t2.micro is too small for a full 5G core.
}

resource "aws_instance" "k8s_master" {
  ami           = "ami-0c7217cdde317cfec" # This is Ubuntu 22.04 in us-east-1. Change if using diff region.
  instance_type = var.instance_type
  key_name      = "KEY_NAME_HERE" # MAKE SURE you create this key pair in AWS Console first!
  security_groups = [aws_security_group.k8s_sg.name]

  tags = {
    Name = "k8s-master"
    Role = "control-plane"
  }
}

resource "aws_instance" "k8s_worker_1" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = var.instance_type
  key_name      = "KEY_NAME_HERE"
  security_groups = [aws_security_group.k8s_sg.name]

  tags = {
    Name = "k8s-worker-1"
    Role = "worker"
  }
}

resource "aws_instance" "k8s_worker_2" {
  ami           = "ami-0c7217cdde317cfec"
  instance_type = var.instance_type
  key_name      = "KEY_NAME_HERE"
  security_groups = [aws_security_group.k8s_sg.name]

  tags = {
    Name = "k8s-worker-2"
    Role = "worker"
  }
}
