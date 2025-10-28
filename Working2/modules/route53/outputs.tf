output "route53_zone_id" {
  value       = aws_route53_zone.main.zone_id
  description = "Hosted zone ID"
}

output "name_servers" {
  value       = aws_route53_zone.main.name_servers
  description = "List of NS records to add in GoDaddy"
}

output "root_record_name" {
  value       = aws_route53_record.root_alias.name
  description = "Root A record name"
}

output "cdn_record_name" {
  value       = try(aws_route53_record.cdn_alias[0].name, null)
  description = "CDN record name (if created)"
}

output "api_record_name" {
  value       = try(aws_route53_record.api_alias[0].name, null)
  description = "API record name (if created)"
}

output "app_domain_name" {
  value       = "app.spakcommgroup.com"
  description = "Public domain name pointing to ALB"
}
