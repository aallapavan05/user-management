#!/bin/bash
# create_users.sh - Automates Linux user creation and group management
# Author: our Name
# Usage: sudo bash create_users.sh users.txt

# 1. Input file passed as first argument
INPUT_FILE=$1

# 2. Define log and password storage locations
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

# 3. Create secure directories if they don't exist
mkdir -p /var/secure
chmod 700 /var/secure

# 4. Initialize log and password files with correct permissions
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

# 5. Read input file line by line
while IFS= read -r line; do
  # 6. Skip empty lines or lines starting with '#'
  if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
    continue
  fi

  # 7. Extract username (before ';') and trim spaces
  username=$(echo "$line" | cut -d';' -f1 | xargs)

  # 8. Extract groups (after ';') and remove spaces
  groups=$(echo "$line" | cut -d';' -f2 | tr -d ' ')

  # 9. Generate a random 12-character password
  password=$(openssl rand -base64 9)

  # 10. Check if user already exists
  if ! id "$username" &>/dev/null; then
    # 11. Create the user with home directory and bash shell
    useradd -m -s /bin/bash "$username"

    # 12. Set the generated password
    echo "$username:$password" | chpasswd

    # 13. Save the credentials to the secure file
    echo "$username:$password" >> "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"

    # 14. Split groups by comma and process each
    IFS=',' read -ra group_list <<< "$groups"
    for g in "${group_list[@]}"; do
      # 15. Create group if it doesn’t exist
      if ! getent group "$g" >/dev/null; then
        groupadd "$g"
      fi
      # 16. Add user to the group
      usermod -aG "$g" "$username"
    done

    # 17. Log success message
    echo "Created user $username" | tee -a "$LOG_FILE"
  else
    # 18. Log if user already exists
    echo "User $username already exists, skipping" | tee -a "$LOG_FILE"
  fi
done < "$INPUT_FILE"
