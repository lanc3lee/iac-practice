provider "aws" {
  region = var.aws_region
}

# Amazon-owned, always-current Ubuntu 22.04 LTS AMI — resolved by filter, not a
# hardcoded ID, so this works correctly regardless of which region you deploy to.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  # Port sets per platform. Extend here if the ELK path needs more than
  # Elasticsearch/Kibana defaults later.
  siem_ports = {
    wazuh = [
      { port = 1514,  desc = "Wazuh agent event collection" },
      { port = 1515,  desc = "Wazuh agent enrollment" },
      { port = 55000, desc = "Wazuh API" },
      { port = 443,   desc = "Wazuh dashboard (HTTPS)" },
    ]
    elk = [
      { port = 9200, desc = "Elasticsearch HTTP" },
      { port = 5601, desc = "Kibana" },
    ]
  }
}

resource "aws_security_group" "siem_practice" {
  name        = "${var.project_tag}-sg"
  description = "Restricts SIEM practice host access to a single IP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  dynamic "ingress" {
    for_each = local.siem_ports[var.siem_platform]
    content {
      description = ingress.value.desc
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = [var.my_ip_cidr]
    }
  }

  egress {
    description = "Allow all outbound (package installs, updates)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_tag}-sg"
    Project = var.project_tag
  }
}

resource "aws_instance" "wazuh_practice" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.siem_practice.id]

  root_block_device {
    volume_type           = "gp3"
    volume_size            = var.ebs_volume_size_gb
    delete_on_termination = true # don't leave orphaned EBS billing after teardown
    encrypted              = true
  }

  tags = {
    Name     = "${var.project_tag}-${var.siem_platform}"
    Project  = var.project_tag
    Platform = var.siem_platform
    TearDown = "end-of-session"
  }
}

