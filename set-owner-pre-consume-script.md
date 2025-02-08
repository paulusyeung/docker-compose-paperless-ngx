Okay, here's a concise recap of the code and the setup steps for using a pre-consume script to assign document owners based on subfolders in Paperless-ngx:

**Code (Using Paperless-ngx API - Recommended):**

Bash

```
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
```

**Setup Steps:**

1. **Install `jq (json praser)`:** On your Paperless-ngx server (where Docker is running), install `jq`:
   
   Bash
   
   ```
   sudo apt-get update  # If using Debian/Ubuntu
   sudo apt-get install jq
   ```

2. **Generate API Token:** In the Paperless-ngx web interface, go to your user profile and create a new API token. Copy this token; you'll need it for the script.

3. **Find the Volume's Host Path:** Use the following command to find the host path for the `paperless` volume:
   
   Bash
   
   ```
   docker volume inspect paperless
   ```
   
   Look for the `"Mountpoint"` value in the output. This is the path on your host system where the volume's data is stored. For example: `/var/lib/docker/volumes/paperless/_data`

4. **Create the `scripts` Directory:** On your *host system*, create a directory named `scripts` inside the volume's host path. For example:
   
   Bash
   
   ```
   mkdir -p /var/lib/docker/volumes/paperless/_data/scripts
   ```

5. **Create and Save the Script:** Create a new file named `set_owner.sh` inside the `scripts` directory you just created. Copy the code provided above into this file.

6. **Replace Placeholders:** In the `set_owner.sh` script:
   
   - Replace `http://your-paperless-ngx-url/api/` with the actual URL of your Paperless-ngx API. If Paperless is running on the same machine as the script, you might use `http://localhost:8000/api/` (adjust the port if necessary). If you are using a reverse proxy, use the public URL.
   - Replace `YOUR_API_TOKEN` with the API token you generated in step 2.

7. **Make the Script Executable:** On your *host system*, make the script executable:
   
   Bash
   
   ```
   chmod +x /var/lib/docker/volumes/paperless/_data/scripts/set_owner.sh
   ```

8. **Configure `docker-compose.env`:** In your `docker-compose.env` file, add or modify the `PAPERLESS_PRE_CONSUME_SCRIPT` variable:
   
   ```
   PAPERLESS_PRE_CONSUME_SCRIPT=/opt/paperless/data/scripts/set_owner.sh
   ```

9. **Restart Containers:** Restart your Paperless-ngx containers for the changes to take effect:
   
   Bash
   
   ```
   docker-compose down
   docker-compose up -d
   ```

10. **Test:** Create subfolders in your consume directory (also a mounted volume) with names that match existing usernames in Paperless-ngx. Place test documents in these subfolders. Check the logs of the `webserver` container (`docker-compose logs webserver`) to see if the script is running correctly and setting the owners.

By following these steps, you'll have a robust solution for dynamically assigning document owners in Paperless-ngx based on subfolders, and your script will persist across container updates.
