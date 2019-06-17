#!/usr/bin/env bash
sudo yum install -y python3 python3-devel gcc postgresql-devel git
git clone https://github.com/dolv/simpleFlaskAppInAWS
mkdir -p ~/.aws/
touch ~/.aws/credentials
chmod 600 ~/.aws/credentials
cat > ~/.aws/credentials <<EOF
[grover-test-account]
aws_access_key_id = AAAAAAAAAAA
aws_secret_access_key = BBBBBBBBBBBBBBBBBBBBBBBB
region = eu-central-1
EOF
cd simpleFlaskAppInAWS
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

