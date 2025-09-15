output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
output "target_group_a_arn" {
  value = aws_lb_target_group.nginx_a.arn
}
output "target_group_b_arn" {
  value = aws_lb_target_group.nginx_b.arn
}
