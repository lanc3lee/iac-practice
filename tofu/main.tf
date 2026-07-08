terraform {
  required_version = ">= 1.6.0" # OpenTofu version constraint — same syntax block name as Terraform

  required_providers {
    aws = {
      source  = "hashicorp/aws" # provider source stays "hashicorp/aws" even under OpenTofu — providers aren't forked
      version = "~> 5.0"
    }
  }

  # Local state for this practice exercise deliberately, NOT remote S3 state.
  # This is a solo practice environment, not the team's shared production infra —
  # remote state + locking only matters once multiple people touch the same state file.
  # Our real project infra (see /architecture) uses S3 + DynamoDB + KMS encryption per ADR-0002/0003.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_tag
      ManagedBy = "opentofu"
      Purpose   = "practice"
    }
  }
}

# ---------------------------------------------------------------------------
# Security group — port rules depend on which SIEM platform we're practicing with.
# Ports are genuinely different between ELK and Wazuh, so this isn't cosmetic:
#
# ELK stack:
#   9200  — Elasticsearch REST API
#   5601  — Kibana web UI
#   5044  — Logstash Beats input
#
# Wazuh:
#   1514  — Wazuh agent event data (TCP/UDP)
#   1515  — Wazuh agent enrollment
#   55000 — Wazuh API
#   443   — Wazuh dashboard (HTTPS)
# ---------------------------------------------------------------------------

resource "aws_security_group" "siem_practice" {
  name        = "${var.project_tag}-sg"
  description = "Security group for SIEM practice instance (${var.siem_platform})"

  # SSH — always needed, always restricted to your own IP only
  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # --- ELK-specific rules, only created when siem_platform = "elk" ---
  dynamic "ingress" {
    for_each = var.siem_platform == "elk" ? [9200, 5601, 5044] : []
    content {
      description = "ELK port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.my_ip_cidr]
    }
  }

  # --- Wazuh-specific rules, only created when siem_platform = "wazuh" ---
  dynamic "ingress" {
    for_each = var.siem_platform == "wazuh" ? [1514, 1515, 55000, 443] : []
    content {
      description = "Wazuh port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.my_ip_cidr]
    }
  }

  egress {
    description = "Allow all outbound (needed for package installs, updates)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------------------------------------------------------------------------
# EC2 instance — the SIEM practice host itself.
# Free-tier-eligible sizing on purpose (see variables.tf) — this is deliberately
# smaller than our real production spec (t3.medium per the NFR matrix).
# ---------------------------------------------------------------------------

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "siem_practice" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.siem_practice.id]

  root_block_device {
    volume_size = var.ebs_volume_size_gb
    volume_type = "gp3" # gp3 is cheaper and faster than gp2, no reason to use gp2 for new resources
    encrypted   = true  # encrypt at rest — good habit to carry into the real project too
  }

  tags = {
    Name = "${var.project_tag}-${var.siem_platform}"
  }
}
