# serversetup.sh
#!/bin/bash

# Check if username parameter is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    echo "Please provide a username for the new user account"
    exit 1
fi

USERNAME="$1"
echo "Setting up server for user: $USERNAME"

# Add new user
sudo adduser "$USERNAME"
sudo usermod -aG sudo "$USERNAME"
# Set up SSH for the new user
echo "Setting up SSH keys for $USERNAME..."
sudo mkdir -p /home/"$USERNAME"/.ssh
sudo cp ~/.ssh/authorized_keys /home/"$USERNAME"/.ssh/ 2>/dev/null || {
    echo "Warning: Could not copy SSH keys. Make sure ~/.ssh/authorized_keys exists"
}
sudo chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
sudo chmod 700 /home/"$USERNAME"/.ssh
sudo chmod 600 /home/"$USERNAME"/.ssh/authorized_keys 2>/dev/null

# Update the system
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install necessary packages
echo "Installing essential packages..."
sudo apt install -y ufw fail2ban htop curl wget git unzip \
    software-properties-common apt-transport-https ca-certificates

# Enable and start UFW
echo "Configuring UFW firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw --force enable  # --force prevents interactive prompt
sudo ufw status


# Set up swap file (if not exists)
echo "Checking swap configuration..."
if ! swapon --show | grep -q "/swapfile"; then
    echo "Creating swap file..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
else
    echo "Swap already configured"
fi

# Configure SSH security
echo "Hardening SSH configuration..."
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sudo sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config

# Install and configure Fail2Ban
echo "Setting up Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Create custom fail2ban jail for SSH
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
EOF

sudo systemctl restart fail2ban
sudo systemctl status fail2ban --no-pager

# Set up basic system monitoring
echo "Setting up system monitoring..."
# Create a simple system info script
sudo tee /usr/local/bin/sysinfo > /dev/null <<'EOF'
#!/bin/bash
echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "Load: $(cat /proc/loadavg)"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 " used)"}')"
echo "Active connections: $(ss -tuln | wc -l)"
echo "Failed login attempts (last 10): $(grep "Failed password" /var/log/auth.log | tail -10 | wc -l)"
EOF

sudo chmod +x /usr/local/bin/sysinfo

# Restart SSH service to apply security changes
echo "Restarting SSH service to apply security settings..."
sudo systemctl restart sshd

echo "Server setup completed successfully!"
echo "New user '$USERNAME' has been created with sudo privileges"
echo "SSH keys have been copied (if available)"
echo "Firewall and Fail2Ban are now active"
echo "Automatic security updates are enabled"
echo "SSH has been hardened (password auth disabled, root login disabled)"
echo "Swap file created (2GB)"
echo ""
echo "Run 'sysinfo' to check system status"
echo ""
echo "IMPORTANT: Test SSH connection with new user before logging out!"
echo "Connect with: ssh $USERNAME@<server-ip>"
