#!/bin/bash
PROJECT_ID="agentic-480806"
KEY_NAME="workshop_key"

echo "===================================================="
echo "📋 VS CODE CONFIGURATION INFO"
echo "===================================================="
echo "Copy the block below into your SSH Config file:"
echo "   Windows: C:\\Users\\NAME\\.ssh\\config"
echo "   Mac/Linux: ~/.ssh/config"
echo "===================================================="
echo ""

gcloud compute instances list \
    --project=$PROJECT_ID \
    --filter="status=RUNNING" \
    --format="csv[no-heading](name,networkInterfaces[0].accessConfigs[0].natIP)" \
    | while IFS=, read -r name ip; do
        if [ -n "$ip" ]; then
            echo "Host $name"
            echo "    HostName $ip"
            echo "    User student"
            echo "    IdentityFile ~/.ssh/$KEY_NAME" 
            echo "    StrictHostKeyChecking no"
            echo "    UserKnownHostsFile /dev/null"
            echo ""
        fi
    done \
2>&1 | tee config

echo "===================================================="
echo "⚠️  WINDOWS USERS:"
echo "1. Copy the '$KEY_NAME' file from here to C:\\Users\\YourName\\.ssh\\"
echo "2. Change 'IdentityFile' above to: IdentityFile C:\\Users\\YourName\\.ssh\\$KEY_NAME"
echo "===================================================="
