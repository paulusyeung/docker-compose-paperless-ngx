#!/bin/bash

# Configuration (REPLACE THESE VALUES)
PAPERLESS_URL="http://your-paperless-ngx-url/api/"  # e.g., http://192.168.1.100:8000/api/
PAPERLESS_TOKEN="YOUR_API_TOKEN"

# Extract the subfolder name
SUBFOLDER=$(dirname "$DOCUMENT_SOURCE_PATH" | xargs basename)

# Function to get user ID by username
get_user_id() {
  local username="$1"
  local user_id=$(curl -s -H "Authorization: Token $PAPERLESS_TOKEN" \
    "$PAPERLESS_URL/users/?username=$username" | \
    jq -r '.results[0].id')
  echo "$user_id"
}

# Get the user ID based on the subfolder name
USER_ID=$(get_user_id "$SUBFOLDER")

# Check if a user was found
if [[ -n "$USER_ID" ]]; then
  export DOCUMENT_OWNER="$USER_ID"
  echo "Setting owner to user ID: $USER_ID (Subfolder: $SUBFOLDER)"
else
  echo "Error: No user found for subfolder: $SUBFOLDER"
  # Optional: Set a default owner if no match is found
  # DEFAULT_USER_ID=$(get_user_id "default_user") # Replace "default_user"
  # if [[ -n "$DEFAULT_USER_ID" ]]; then
  #   export DOCUMENT_OWNER="$DEFAULT_USER_ID"
  #   echo "Setting owner to default user ID: $DEFAULT_USER_ID"
  # fi
fi