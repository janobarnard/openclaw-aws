# Outputs - Minimal Deployment

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.openclaw.id
}

output "public_ip" {
  description = "Public IP (may change on restart)"
  value       = aws_instance.openclaw.public_ip
}

output "connect_command" {
  description = "Connect via SSM"
  value       = "aws ssm start-session --target ${aws_instance.openclaw.id} --region ${var.aws_region}"
}

output "next_steps" {
  value = <<-EOT

    ╔════════════════════════════════════════════════════════════╗
    ║                   SETUP COMPLETE! 🎉                       ║
    ╠════════════════════════════════════════════════════════════╣
    ║                                                            ║
    ║  1. Connect to your instance:                              ║
    ║                                                            ║
    ║     aws ssm start-session --target ${aws_instance.openclaw.id} --region ${var.aws_region}
    ║                                                            ║
    ║  2. Initialize OpenClaw (enter your API keys):             ║
    ║                                                            ║
    ║     sudo -u openclaw openclaw onboard --install-daemon      ║
    ║                                                            ║
    ║  3. Open dashboard locally (SSM port forward):             ║
    ║                                                            ║
    ║     aws ssm start-session --target ${aws_instance.openclaw.id} --region ${var.aws_region} \
    ║       --document-name AWS-StartPortForwardingSession \
    ║       --parameters '{"portNumber":["18789"],"localPortNumber":["18789"]}'
    ║                                                            ║
    ║     http://localhost:18789/                                ║
    ║     Token: sudo -u openclaw openclaw config get gateway.auth.token ║
    ║                                                            ║
    ║  4. Message your bot!                                      ║
    ║                                                            ║
    ╚════════════════════════════════════════════════════════════╝
  EOT
}
