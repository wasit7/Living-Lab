#!/bin/bash
PROJECT_ID="agentic-480806"
ZONE="asia-southeast1-a"

echo "⚠️  WARNING: Deleting ALL 'vm-*' instances in $ZONE ($PROJECT_ID)."
read -p "Are you sure? (y/n): " CONFIRM

if [[ "$CONFIRM" == "y" ]]; then
    echo "🔥 Deleting VMs..."
    VM_LIST=$(gcloud compute instances list --project=$PROJECT_ID --filter="name:vm-*" --format="value(name)")
    
    if [ -z "$VM_LIST" ]; then
        echo "Example: No VMs found to delete."
    else
        echo "$VM_LIST" | xargs -r gcloud compute instances delete --project=$PROJECT_ID --zone=$ZONE --quiet
        echo "✅ All VMs deleted."
    fi
else
    echo "❌ Cancelled."
fi
