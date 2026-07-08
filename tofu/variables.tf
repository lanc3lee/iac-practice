variable "aws_region" {
  description = "AWS region to deploy into. Pick one close to you for lower latency during practice."
  type        = string
  default     = "ap-southeast-1" # Singapore
}

variable "instance_type" {
  description = "EC2 instance size. t2.micro / t3.micro are AWS free-tier eligible — deliberately undersized vs our real production spec (t3.medium), since this is a practice/PoC exercise, not the real deployment."
  type        = string
  default     = "t2.micro"
}

variable "ebs_volume_size_gb" {
  description = "Root/data EBS volume size in GB. Free tier covers up to 30GB total EBS — keep practice volumes well under that."
  type        = number
  default     = 20
}

variable "siem_platform" {
  description = "Which SIEM platform this practice environment is provisioning ports/sizing for. Affects which security group rules get applied. One of: 'elk' or 'wazuh'. This choice itself is still an open decision — see the related ADR."
  type        = string
  default     = "wazuh"

  validation {
    condition     = contains(["elk", "wazuh"], var.siem_platform)
    error_message = "siem_platform must be either \"elk\" or \"wazuh\"."
  }
}

variable "my_ip_cidr" {
  description = "Your own IP address in CIDR form (e.g. 1.2.3.4/32), used to restrict SSH/dashboard access to just you during practice. Never leave this as 0.0.0.0/0 — find your IP at https://checkip.amazonaws.com"
  type        = string
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair in your AWS account, used for SSH access. Create one first via: aws ec2 create-key-pair --key-name siem-practice --query 'KeyMaterial' --output text > siem-practice.pem"
  type        = string
}

variable "project_tag" {
  description = "Tag applied to all resources for easy identification/cleanup in a shared or free-tier account."
  type        = string
  default     = "cyberstorm-siem-practice"
}
