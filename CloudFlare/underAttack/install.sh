#!/bin/bash
install_dir="/usr/local/under_attack"
watcher_script="$install_dir/under_attack_watcher.sh"
service_file="/etc/systemd/system/under_attack_watcher.service"
cf_config_dir="/usr/local/etc/under_attack"
cf_config_file="$cf_config_dir/cloudflare.config"   

# Create installation directory
mkdir -p "$install_dir"
# Create CloudFlare config directory
mkdir -p "$cf_config_dir"
# Create a sample CloudFlare config file if it doesn't exist
if [ ! -f "$cf_config_file" ]; then
    cat <<EOL > "$cf_config_file"
# CloudFlare API Configuration
# Replace the placeholders with your actual CloudFlare API credentials and zone information.
API_TOKEN="your_api_token_here"
ZONE_ID="your_zone_id_here"
EOL
    echo "Sample CloudFlare config file created at '$cf_config_file'. Please update it with your actual credentials."
fi

# Copy watcher script
cp ./under_attack_watcher.sh "$watcher_script"
chmod +x "$watcher_script"  
# Create systemd service file
cp ./under_attack_watcher.service "$service_file"
# Reload systemd to recognize the new service
systemctl daemon-reload
# Enable the service to start on boot
systemctl enable under_attack_watcher.service
# Start the service immediately
systemctl start under_attack_watcher.service 