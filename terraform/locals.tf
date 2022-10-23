locals {
  name          = "lambda-apigateway-demo"
  author        = "Eunchurn Park"
  email         = "eunchurn.park@gmail.com"
  lambda_memory = 128

  tags = {
    Name      = "lambda-apigateway-demo"
    GitRepo   = "https://github.com/eunchurn/terraform-typescript-lambda-apigateway"
    ManagedBy = "Terraform"
    Owner     = "${local.email}"
  }
}
