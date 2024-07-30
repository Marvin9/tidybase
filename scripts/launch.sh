#!/bin/bash
# variables
# efs_id
echo ${efs_id}
sudo su
sudo yum install -y amazon-efs-utils
mkdir /tidybase
cd /tidybase
mkdir data
mkdir logs
# sudo mount -t efs -o tls ${efs_id}:/ data
wget https://github.com/pocketbase/pocketbase/releases/download/v0.22.18/pocketbase_0.22.18_linux_amd64.zip
unzip pocketbase_0.22.18_linux_amd64.zip
chmod +x pocketbase
nohup ./pocketbase serve --http="0.0.0.0:80" --dir="./data" > ./logs/pocketbase.log 2>&1 &
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id test/tidybase --query 'SecretString' | jq -r 'fromjson')
ADMIN_EMAIL=$(echo $SECRET_JSON | jq -r '.ADMIN_EMAIL')
ADMIN_PASSWORD=$(echo $SECRET_JSON | jq -r '.ADMIN_PASSWORD')
curl -X POST http://localhost:80/api/admins \
  -H "Content-Type: application/json" \
  -d '{
    "email": "'"$ADMIN_EMAIL"'",
    "password": "'"$ADMIN_PASSWORD"'",
    "passwordConfirm": "'"$ADMIN_PASSWORD"'"
  }'
# LOGIN=$(curl -X POST http://localhost:80/api/admins/auth-with-password \
#   -H "Content-Type: application/json" \
#   -d '{
#     "identity": "'"$ADMIN_EMAIL"'",
#     "password": "'"$ADMIN_PASSWORD"'"
#   }')

# TOKEN=$(echo $LOGIN | jq -r '.token')