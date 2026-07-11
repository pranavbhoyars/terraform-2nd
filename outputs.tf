output "ec2_global_public_ip" {
  value       = module.infrastructure.instance_public_ip
  description = "The public IP of the created EC2 instance"
}
output "ecr_repository_url" {
  value = aws_ecr_repository.nginx_repo.repository_url
}
