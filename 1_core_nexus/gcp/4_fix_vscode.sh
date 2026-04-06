#!/bin/bash
PROJECT_ID="agentic-480806"
ZONE="asia-southeast1-a"

echo "🚑 VS CODE FIX TOOL"
echo "This will delete the .vscode-server folder on the remote VM."
echo "Use this if you get 'Failed to set up dynamic port forwarding'."
echo ""
read -p "Enter the VM number to fix (e.g., enter 1 for vm-1): " VM_NUM

VM_NAME="vm-$VM_NUM"

echo "Attempting to fix $VM_NAME..."
gcloud compute ssh $VM_NAME --project=$PROJECT_ID --zone=$ZONE --command="rm -rf ~/.vscode-server"

if [ $? -eq 0 ]; then
    echo "✅ Cleaned up $VM_NAME."
    echo "👉 Now: In VS Code, press F1 -> 'Developer: Reload Window' and try again."
else
    echo "❌ Failed to connect. Is the VM running?"
fi
