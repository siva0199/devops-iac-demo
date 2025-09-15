output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}
output "ec2_instance_profile" {
  value = aws_iam_instance_profile.ec2.arn
}
output "lambda_execution_role_arn" {
  value = aws_iam_role.lambda_execution.arn
}
