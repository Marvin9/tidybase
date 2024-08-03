#!/bin/bash
# variables
# efs_id
# secret_id
# cloudwatch_agent_config_ssm
sudo su
sudo yum install -y amazon-efs-utils amazon-cloudwatch-agent
mkdir /tidybase
cd /tidybase
mkdir data
mkdir logs
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${cloudwatch_agent_config_ssm} -s
# sudo mount -t efs -o tls ${efs_id} /tidybase/data/
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dns}:/ /tidybase/data/
wget https://github.com/pocketbase/pocketbase/releases/download/v0.22.18/pocketbase_0.22.18_linux_amd64.zip
unzip pocketbase_0.22.18_linux_amd64.zip
chmod +x pocketbase

if [ -z "$(ls -A /tidybase/data)" ]; then
    nohup ./pocketbase serve --http="0.0.0.0:80" --dir="./data" > ./logs/pocketbase.log 2>&1 &

    SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${secret_id} --query 'SecretString' | jq -r 'fromjson')
    ADMIN_EMAIL=$(echo $SECRET_JSON | jq -r '.ADMIN_EMAIL')
    ADMIN_PASSWORD=$(echo $SECRET_JSON | jq -r '.ADMIN_PASSWORD')
    ./pocketbase admin create $ADMIN_EMAIL $ADMIN_PASSWORD
else
    nohup ./pocketbase serve --http="0.0.0.0:80" --dir="./data" --automigrate=false > ./logs/pocketbase.log 2>&1 &
fi