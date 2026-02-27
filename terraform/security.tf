resource "aws_security_group" "k8s_sg" {
  name        = "5g_lab_sg"
  description = "Allow 5G and K8s traffic"

  # Allow SSH (so Ansible can connect later)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In prod, restrict to your IP
  }

  # Allow all internal traffic between the nodes (Crucial for K8s & 5G)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true 
  }

  # Outbound internet access (to download packages)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
