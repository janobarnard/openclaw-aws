# OpenClaw AWS - Minimal Deployment

**Just like a VPS.** No domain. No Secrets Manager. Just EC2.

## Cost: ~$10/month

| Component | Cost |
|-----------|------|
| EC2 t3.micro | $7.59 |
| EBS 20GB | $1.60 |
| **Total** | **~$9-10** |

## Architecture

```
EC2 (polls) → Telegram API
EC2 (calls) → Anthropic API
```

No inbound traffic. Configure OpenClaw interactively, just like your VPS.

## Quick Start

```bash
terraform init
terraform apply
```

## Setup (after deploy)

```bash
# 1. Connect
aws ssm start-session --target <instance-id>

# 2. Initialize OpenClaw (enter your tokens)
sudo -u openclaw openclaw init

# 3. Start
sudo systemctl start openclaw

# 4. Message your Telegram bot! 🎉
```

## Useful Commands

```bash
# View logs
sudo journalctl -u openclaw -f

# Restart
sudo systemctl restart openclaw

# Check status
sudo systemctl status openclaw
```

## Notes

- Public IP may change on instance restart
- Config stored in `/home/openclaw/.openclaw/config.json`
- Workspace at `/home/openclaw/.openclaw/workspace/`
