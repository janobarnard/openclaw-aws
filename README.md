# OpenClaw on AWS

One command to deploy OpenClaw on AWS.

## Cost: ~$10/month

## Setup

```bash
git clone https://github.com/rimaslogic/openclawonaws.git
cd openclawonaws
./setup.sh
```

The wizard will:
1. ✅ Check prerequisites (Terraform, AWS CLI)
2. ✅ Ask for your Telegram bot token
3. ✅ Ask for your Anthropic API key
4. ✅ Deploy EC2 instance
5. ✅ Configure OpenClaw
6. ✅ Start the service

**Then message your Telegram bot!**

## Prerequisites

```bash
# macOS
brew install terraform awscli

# Ubuntu
apt install terraform awscli

# Configure AWS
aws configure
```

## Commands

```bash
# Connect to instance
aws ssm start-session --target <instance-id>

# View logs
sudo journalctl -u openclaw -f

# Destroy
cd terraform && terraform destroy
```

## License

MIT
