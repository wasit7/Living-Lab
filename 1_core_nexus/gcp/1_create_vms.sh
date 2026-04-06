#!/bin/bash
PROJECT_ID="agentic-480806"
ZONE="asia-southeast1-a"
KEY_FILE="$HOME/.ssh/workshop_key_formatted.pub"

# --- LOGIN CHECK ---
echo "🔍 Checking authentication..."
if ! gcloud auth print-access-token >/dev/null 2>&1; then
    echo "❌ Error: You are not logged in."
    echo "👉 Run: gcloud auth login"
    exit 1
fi

# --- PROJECT CHECK ---
CURRENT_PROJECT=$(gcloud config get-value project 2>/dev/null)
if [ "$CURRENT_PROJECT" != "$PROJECT_ID" ]; then
    echo "⚠️  Switching active project to: $PROJECT_ID"
    gcloud config set project $PROJECT_ID
fi

# --- KEY CHECK ---
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Error: Key file missing. Run './0_create_key.sh' first."
    exit 1
fi

# --- CREATE VMS ---
read -p "Enter number of VMs to create: " NUM_VMS
echo "🚀 Creating $NUM_VMS Spot VMs in $ZONE..."

if gcloud compute instances create $(seq -f "vm-%g" 1 $NUM_VMS) \
    --zone=$ZONE \
    --machine-type=e2-standard-2 \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --provisioning-model=SPOT \
    --instance-termination-action=STOP \
    --metadata-from-file ssh-keys=$KEY_FILE \
    --tags=http-server,https-server; then
    
    echo ""
    echo "✅ Success! $NUM_VMS VMs are running."
else
    echo ""
    echo "❌ Creation Failed. (If they already exist, run Step 3 to clean up)."
    exit 1
fi
