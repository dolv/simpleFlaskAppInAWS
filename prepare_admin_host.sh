#!/usr/bin/env bash
sudo yum install -y python3 python3-devel gcc postgresql-devel git
git clone https://github.com/dolv/simpleFlaskAppInAWS
cd simpleFlaskAppInAWS
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

