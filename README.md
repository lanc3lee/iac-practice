# iac-practice

Personal OpenTofu practice repo — provisioning AWS infrastructure as part of learning IaC for the CyberStorm SIEM project.

Not the production CyberStorm repo — this is a personal, disposable, free-tier practice environment. See the writeup at soc.lanc3.com/practice/IaC for context.

## Structure

- `tofu/` — OpenTofu config provisioning an EC2 host sized/networked for either ELK or Wazuh practice, controlled by the `siem_platform` variable.
