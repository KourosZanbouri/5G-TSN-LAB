output "master_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "worker_ips" {
  value = [
    aws_instance.k8s_worker_1.public_ip,
    aws_instance.k8s_worker_2.public_ip
  ]
}