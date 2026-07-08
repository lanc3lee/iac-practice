output "instance_public_ip" {
  description = "Public IP of the SIEM practice instance — use this to SSH in and to reach the dashboard/API ports."
  value       = aws_instance.siem_practice.public_ip
}

output "instance_id" {
  description = "EC2 instance ID — useful for AWS CLI lookups, stopping/starting, or CloudWatch queries."
  value       = aws_instance.siem_practice.id
}

output "security_group_id" {
  description = "Security group ID — reference this if you add more rules later without recreating the group."
  value       = aws_security_group.siem_practice.id
}

output "siem_platform_deployed" {
  description = "Which SIEM platform's ports this instance was configured for."
  value       = var.siem_platform
}

output "ssh_command" {
  description = "Ready-to-use SSH command."
  value       = "ssh -i ${var.key_pair_name}.pem ubuntu@${aws_instance.siem_practice.public_ip}"
}
