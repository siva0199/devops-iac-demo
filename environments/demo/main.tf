provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../../modules/vpc"
  region = var.region
}

module "lambda" {
  source                    = "../../modules/lambda"
  lambda_execution_role_arn = module.iam.lambda_execution_role_arn
}

module "iam" {
  source        = "../../modules/iam"
  s3_bucket_arn = module.lambda.s3_bucket_arn
}

module "alb" {
  source             = "../../modules/alb"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = [module.vpc.public_subnet_id_a, module.vpc.public_subnet_id_b]
}
module "ecs" {
  source                      = "../../modules/ecs"
  region                      = var.region
  vpc_id                      = module.vpc.vpc_id
  private_app_subnet_id       = module.vpc.private_app_subnet_id
  ec2_instance_profile        = module.iam.ec2_instance_profile
  ecs_task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  target_group_a_arn          = module.alb.target_group_a_arn
  target_group_b_arn          = module.alb.target_group_b_arn
}
