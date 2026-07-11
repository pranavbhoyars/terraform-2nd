resource "aws_ecr_repository" "nginx_repo" {
  name                 = "nginx-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "nginx-app"
  }
}
