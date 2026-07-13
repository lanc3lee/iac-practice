# iac-practice

Personal OpenTofu practice repo — provisioning AWS infrastructure as part of learning IaC for the CyberStorm SIEM project.

Not the production CyberStorm repo — this is a personal, disposable, free-tier practice environment. See the writeup at soc.lanc3.com/practice/IaC for context.

## Structure

```
tofu/                           # base practice exercise — free-tier sized (t3.micro), automated
├── main.tf                    # provider, security group, EC2 instance (incl. user_data bootstrap)
├── variables.tf               # inputs — region, instance size, siem_platform (elk/wazuh), IP, key pair
├── outputs.tf                 # public IP, instance ID, security group ID, SSH command
├── terraform.tfvars.example   # sample values — copy to terraform.tfvars and fill in your own
└── templates/
    ├── elk-install.sh.tpl     # cloud-init bootstrap script — installs Elasticsearch + Kibana
    └── wazuh-install.sh.tpl   # cloud-init bootstrap script — installs Wazuh (all-in-one)

manual-wazuh-us-east1/          # variant — larger instance (t3.medium), manual install, no bootstrap script
├── main.tf                    # same structure, no user_data — install is done by hand over SSH
├── variables.tf
├── outputs.tf
└── terraform.tfvars.example
```

**Which folder should you use?**
- **`tofu/`** — start here. Free-tier sized, fully automated install via `user_data`, works for either ELK or Wazuh via the `siem_platform` variable. This is the base exercise documented at [soc.lanc3.com/practice/IaC](https://soc.lanc3.com/practice/IaC) 

- **`wazuh-manual-us-east1/`** — use this if `tofu/`'s free-tier instance size isn't enough RAM for your install (Wazuh's all-in-one install needs more than `t3.micro`'s 1GB). Requires switching your AWS account off the Free plan to launch non-free-tier instance types — see the note on AWS's July 2025 Free Tier restructuring if you hit an `InvalidParameterCombination` error. This variant does the software install manually over SSH rather than via bootstrap script.

## What this provisions

One EC2 host (`t3.micro`, free-tier eligible), one encrypted EBS volume, and one security group — networked and bootstrapped for **either ELK or Wazuh**, controlled by a single variable (`siem_platform`), since that platform choice is still an open decision for the real CyberStorm SIEM project.

Software install is automated via `user_data` (cloud-init) at first boot — no manual SSH steps required to get from `tofu apply` to a running dashboard. See the bootstrap writeup linked above for how to confirm install completion and troubleshoot.

## Quick start

```bash
cd tofu/
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars — set my_ip_cidr, key_pair_name, and siem_platform ("elk" or "wazuh")

tofu init
tofu plan
tofu apply
```

Wait a few minutes after `apply` completes for the bootstrap script to finish, then check via SSH:

```bash
cloud-init status --wait
cat /var/log/siem-bootstrap-done.log
```

Tear down when done, to avoid leaving resources running on the free-tier account:

```bash
tofu destroy
```

## Notes

- State is local, not remote — this is a solo practice repo, not the team's shared infra. Remote state (S3 + DynamoDB + KMS encryption) is used for the real CyberStorm project per ADR-0002/ADR-0003, not repeated here.
- `terraform.tfvars`, `*.tfstate`, and `.terraform/` are gitignored — never commit real IP addresses, state, or provider caches.
