#!/bin/bash
#
# OpenClaw AWS Setup - Interactive Wizard
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════╗"
echo "║     OpenClaw on AWS - Setup Wizard    ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Step 1: Check prerequisites
echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

MISSING=()

if ! command -v terraform &> /dev/null; then
    MISSING+=("terraform")
fi

if ! command -v aws &> /dev/null; then
    MISSING+=("aws-cli")
fi

if [ ${#MISSING[@]} -ne 0 ]; then
    echo -e "${RED}Missing: ${MISSING[*]}${NC}"
    echo ""
    echo "Install with:"
    echo "  macOS:  brew install terraform awscli"
    echo "  Ubuntu: apt install terraform awscli"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}AWS not configured!${NC}"
    echo ""
    echo "Run: aws configure"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites met${NC}"
echo ""

# Step 2: Get Telegram token
echo -e "${YELLOW}[2/6] Telegram Bot Token${NC}"
echo "Get one from @BotFather on Telegram"
echo ""
read -p "Token: " TELEGRAM_TOKEN

if [ -z "$TELEGRAM_TOKEN" ]; then
    echo -e "${RED}Token required${NC}"
    exit 1
fi
echo ""

# Step 3: Get Anthropic key
echo -e "${YELLOW}[3/6] Anthropic API Key${NC}"
echo "Get one from console.anthropic.com"
echo ""
read -p "Key: " ANTHROPIC_KEY

if [ -z "$ANTHROPIC_KEY" ]; then
    echo -e "${RED}Key required${NC}"
    exit 1
fi
echo ""

# Step 4: Select region
echo -e "${YELLOW}[4/6] AWS Region${NC}"
echo "1) eu-central-1 (Frankfurt)"
echo "2) us-east-1 (N. Virginia)"  
echo "3) us-west-2 (Oregon)"
echo ""
read -p "Choose [1-3, default 1]: " REGION_CHOICE

case $REGION_CHOICE in
    2) AWS_REGION="us-east-1" ;;
    3) AWS_REGION="us-west-2" ;;
    *) AWS_REGION="eu-central-1" ;;
esac

echo -e "Region: ${GREEN}$AWS_REGION${NC}"
echo ""

# Step 5: Deploy
echo -e "${YELLOW}[5/6] Deploying (~3 min)...${NC}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/terraform"

cat > terraform.tfvars << EOF
aws_region = "$AWS_REGION"
EOF

terraform init -input=false > /dev/null
terraform apply -auto-approve

INSTANCE_ID=$(terraform output -raw instance_id)
echo -e "${GREEN}✓ Instance: $INSTANCE_ID${NC}"
echo ""

# Step 6: Configure
echo -e "${YELLOW}[6/6] Configuring OpenClaw...${NC}"
echo "Waiting for instance..."

aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"

echo "Installing OpenClaw (1-2 min)..."
sleep 60

# Create config file content (base64 encoded to handle special chars)
CONFIG_JSON=$(cat << EOF
{
  "model": {
    "provider": "anthropic",
    "model": "claude-sonnet-4-20250514"
  },
  "anthropicApiKey": "$ANTHROPIC_KEY",
  "channels": {
    "telegram": {
      "botToken": "$TELEGRAM_TOKEN"
    }
  }
}
EOF
)

CONFIG_B64=$(echo "$CONFIG_JSON" | base64 -w0 2>/dev/null || echo "$CONFIG_JSON" | base64)

# Send commands via SSM
COMMAND_ID=$(aws ssm send-command \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "{\"commands\":[
        \"mkdir -p /home/openclaw/.openclaw\",
        \"echo '$CONFIG_B64' | base64 -d > /home/openclaw/.openclaw/config.json\",
        \"chown -R openclaw:openclaw /home/openclaw/.openclaw\",
        \"systemctl restart openclaw\"
    ]}" \
    --region "$AWS_REGION" \
    --query 'Command.CommandId' \
    --output text)

# Wait for command to complete
sleep 10
aws ssm wait command-executed \
    --command-id "$COMMAND_ID" \
    --instance-id "$INSTANCE_ID" \
    --region "$AWS_REGION" 2>/dev/null || true

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         SETUP COMPLETE! 🎉            ║${NC}"  
echo -e "${GREEN}╚═══════════════════════════════════════╝${NC}"
echo ""
echo "Message your Telegram bot now!"
echo ""
echo "Instance: $INSTANCE_ID"
echo "Region:   $AWS_REGION"
echo ""
echo "Commands:"
echo "  Connect: aws ssm start-session --target $INSTANCE_ID"
echo "  Logs:    sudo journalctl -u openclaw -f"
echo "  Destroy: cd terraform && terraform destroy"
