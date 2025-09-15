output "alb_dns" {
  value = module.alb.alb_dns_name
}
output "api_url" {
  value = "${module.lambda.api_endpoint}/upload"
}
