#!/usr/bin/env bash

sed -i -E "s/(.*dbconnection_string =.*)localhost:5432(.*)/\1$GROVER_DB_HOST_PORT\2/" ./config.py
sed -i -E "s/(.*dbconnection_string =.*)dbuser:22222(.*)/\1$GROVER_DB_USER:$GROVER_DB_PASSWORD\2/" ./config.py
python3 ./app.py