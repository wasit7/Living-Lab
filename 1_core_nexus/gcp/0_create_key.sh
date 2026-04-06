#!/bin/bash
KEY_PATH="$HOME/.ssh/workshop_key"
USER_NAME="student"

echo "🔑 Step 0: Setting up SSH Keys..."
mkdir -p "$HOME/.ssh"

if [ ! -f "$KEY_PATH" ]; then
    ssh-keygen -t rsa -f $KEY_PATH -C $USER_NAME -N ""
    echo "✅ Key generated at: $KEY_PATH"
else
    echo "✅ Key already exists."
fi

# Create the format Google needs (username:key)
echo "$USER_NAME:$(cat ${KEY_PATH}.pub)" > ${KEY_PATH}_formatted.pub
echo "📄 Formatted key created at: ${KEY_PATH}_formatted.pub"
