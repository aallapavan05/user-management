#!/bin/bash
# create_users.sh - Simple version (works in WSL/Ubuntu)

INPUT_FILE=$1
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.txt"

mkdir -p /var/secure
chmod 700 /var/secure
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
touch "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

while IFS= read -r line; do
  # Skip empty lines and comments
  if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
    continue
  fi

  username=$(echo "$line" | cut -d';' -f1 | xargs)
  groups=$(echo "$line" | cut -d';' -f2 | tr -d ' ')
  password=$(openssl rand -base64 9)

  if ! id "$username" &>/dev/null; then
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    echo "$username:$password" >> "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"

    IFS=',' read -ra group_list <<< "$groups"
    for g in "${group_list[@]}"; do
      if ! getent group "$g" >/dev/null; then
        groupadd "$g"
      fi
      usermod -aG "$g" "$username"
    done

    echo "Created user $username" | tee -a "$LOG_FILE"
  else
    echo "User $username already exists, skipping" | tee -a "$LOG_FILE"
  fi
done < "$INPUT_FILE"

