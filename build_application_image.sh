#!/usr/bin/env bash

tee .dockerignore <<-'EOF'
*
!app.py
!models.py
!config.py
!db_migration_manager.py
!templates/**
!entrypoint.sh
!requirements.txt
EOF

docker build -t grover-test-app:latest .