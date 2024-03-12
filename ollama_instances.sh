#!/bin/bash

# Check if the script is being run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (using sudo)" 
   exit 1
fi

# Function to create instances
create_instances() {
  # Check if ollama.service exists
  if [ ! -f /etc/systemd/system/ollama.service ]; then
    echo "Error: /etc/systemd/system/ollama.service does not exist."
    exit 1
  fi

  # Get the number of instances from the user
  read -p "Enter the number of instances to create (1-54100): " X

  # Validate the input
  if ! [[ "$X" =~ ^[0-9]+$ ]] || [ "$X" -lt 1 ] || [ "$X" -gt 54100 ]; then
    echo "Error: Invalid input. Please enter a number between 1 and 54100."
    exit 1
  fi

  # Create instances
  for ((i=1; i<=X; i++)); do
    if [ -f "/etc/systemd/system/ollama-$i.service" ]; then
      echo "ollama-$i.service already exists. Skipping..."
    else
      cp /etc/systemd/system/ollama.service "/etc/systemd/system/ollama-$i.service"
      sed -i "s/Description=Ollama Service/Description=Ollama Service $i/" "/etc/systemd/system/ollama-$i.service"
      sed -i "/RestartSec=3/a Environment=\"OLLAMA_ORIGINS=*\"\nEnvironment=\"OLLAMA_HOST=127.0.0.1:$((11434+i))\"" "/etc/systemd/system/ollama-$i.service"
      echo "ollama-$i.service created."
    fi
  done

  # Reload systemd and start/enable services
  systemctl daemon-reload
  for ((i=1; i<=X; i++)); do
    systemctl start "ollama-$i.service"
    systemctl enable "ollama-$i.service"
  done

  # Configure Nginx load balancer
  if ! command -v nginx &> /dev/null; then
    echo "Nginx is not installed. Please install Nginx and add the following configuration manually:"
    echo "upstream backend {"
    for ((i=1; i<=X; i++)); do
      echo "  server 127.0.0.1:$((11434+i));"
    done
    echo "}"
    echo ""
    echo "server {"
    echo "  listen 11433;"
    echo "  location / {"
    echo "    proxy_pass http://backend;"
    echo "    proxy_set_header Host \$host;"
    echo "    proxy_set_header X-Real-IP \$remote_addr;"
    echo "    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
    echo "    proxy_set_header X-Forwarded-Proto \$scheme;"
    echo "  }"
    echo "}"
  else
    # Get the list of enabled Nginx configuration files
    enabled_configs=($(ls -1 /etc/nginx/sites-enabled/))
    if [ ${#enabled_configs[@]} -eq 0 ]; then
      echo "No Nginx configuration files are enabled."
      exit 1
    fi

    # Prompt the user to choose a configuration file
    echo "Please choose an Nginx configuration file to modify:"
    for ((i=0; i<${#enabled_configs[@]}; i++)); do
      echo "$((i+1)). ${enabled_configs[$i]}"
    done
    read -p "Enter the number corresponding to the configuration file: " config_choice
    if ! [[ "$config_choice" =~ ^[0-9]+$ ]] || [ "$config_choice" -lt 1 ] || [ "$config_choice" -gt ${#enabled_configs[@]} ]; then
      echo "Invalid choice. Exiting..."
      exit 1
    fi
    selected_config="/etc/nginx/sites-enabled/${enabled_configs[$((config_choice-1))]}"

    # Backup the selected configuration file
    cp "$selected_config" "${selected_config}.bak"

    # Add the upstream block
    echo "upstream backend {" >> "$selected_config"
    for ((i=0; i<=X; i++)); do
      echo "  server 127.0.0.1:$((11434+i));" >> "$selected_config"
    done
    echo "}" >> "$selected_config"

    # Add the server block
    echo "" >> "$selected_config"
    echo "server {" >> "$selected_config"
    echo "  listen 11433;" >> "$selected_config"
    echo "  location / {" >> "$selected_config"
    echo "    proxy_pass http://backend;" >> "$selected_config"
    echo "    proxy_set_header Host \$host;" >> "$selected_config"
    echo "    proxy_set_header X-Real-IP \$remote_addr;" >> "$selected_config"
    echo "    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> "$selected_config"
    echo "    proxy_set_header X-Forwarded-Proto \$scheme;" >> "$selected_config"
    echo "  }" >> "$selected_config"
    echo "}" >> "$selected_config"

    # Test Nginx configuration and reload
    nginx -t
    if [ $? -eq 0 ]; then
      systemctl reload nginx
      echo "Nginx configuration updated and reloaded successfully."
    else
      echo "Nginx configuration test failed. Rolling back..."
      mv "${selected_config}.bak" "$selected_config"
    fi
  fi
}

# Function to delete instances
delete_instances() {
  # Find all ollama-x.service files
  instance_files=($(ls -1 /etc/systemd/system/ollama-*.service 2>/dev/null))
  if [ ${#instance_files[@]} -eq 0 ]; then
    echo "No ollama-x.service files found."
    exit 0
  fi

  # Stop and disable services
  for file in "${instance_files[@]}"; do
    instance_num=$(echo "$file" | sed -n 's/.*ollama-\([0-9]\+\)\.service/\1/p')
    systemctl stop "ollama-$instance_num.service"
    systemctl disable "ollama-$instance_num.service"
    rm "$file"
    echo "ollama-$instance_num.service stopped, disabled, and deleted."
  done

  # Reload systemd
  systemctl daemon-reload
}

# Main script
echo "Please choose an action:"
echo "1. Create instances"
echo "2. Delete instances"
read -p "Enter your choice (1 or 2): " choice

case $choice in
  1)
    create_instances
    ;;
  2)
    delete_instances
    ;;
  *)
    echo "Invalid choice. Exiting..."
    exit 1
    ;;
esac
