# cloudwatch agent status
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status

# From the terminal window for the instance, run the df -T command to verify that the EFS file system is mounted.
df -T