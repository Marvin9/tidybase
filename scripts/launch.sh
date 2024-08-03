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

mount_ip=$(dig +short ${efs_dns})

while [ "$mount_ip" = "" ]
do
  echo "dns for mount unresolved, sleeping 10"
  sleep 10
  mount_ip=$(dig +short ${efs_dns})
done

sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dns}:/ /tidybase/data/
wget https://github.com/pocketbase/pocketbase/releases/download/v0.22.18/pocketbase_0.22.18_linux_amd64.zip
unzip pocketbase_0.22.18_linux_amd64.zip
chmod +x pocketbase

SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${secret_id} --query 'SecretString' | jq -r 'fromjson')
ADMIN_EMAIL=$(echo $SECRET_JSON | jq -r '.ADMIN_EMAIL')
ADMIN_PASSWORD=$(echo $SECRET_JSON | jq -r '.ADMIN_PASSWORD')
S3_BACKUP_BUCKET=$(echo $SECRET_JSON | jq -r '.S3_BACKUP_BUCKET')

if [ -z "$(ls -A /tidybase/data)" ]; then
    nohup ./pocketbase serve --http="0.0.0.0:80" --dir="./data" > ./logs/pocketbase.log 2>&1 &

    ./pocketbase admin create $ADMIN_EMAIL $ADMIN_PASSWORD --dir="./data"
else
    nohup ./pocketbase serve --http="0.0.0.0:80" --dir="./data" --automigrate=false > ./logs/pocketbase.log 2>&1 &
fi

until curl --output /dev/null --silent --head --fail http://localhost; do
    printf '.'
    sleep 5
done

response=$(curl -X POST http://localhost/api/admins/auth-with-password \
    -H "Content-Type: application/json" \
    -d '{"identity": "'"$ADMIN_EMAIL"'", "password": "'"$ADMIN_PASSWORD"'"}' -s)

TOKEN=$(echo $response | jq -r '.token')

curl 'http://localhost/api/settings' \
        -X 'PATCH' \
        -H 'Authorization: '"$TOKEN"'' \
        -H 'Content-Type: application/json' \
        --data-raw '{"backups":{"cron":"*/15 * * * *","cronMaxKeep":2}}' \
        --insecure
