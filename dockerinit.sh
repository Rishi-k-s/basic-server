#!/bin/bash

# Docker Installation Script
# Usage: ./dockerinit.sh [username]

echo "Starting Docker installation..."

# Check if username is provided, otherwise use current user
if [ -n "$1" ]; then
    USERNAME="$1"
else
    USERNAME="$(whoami)"
fi

echo "Installing Docker for user: $USERNAME"

# Remove old Docker packages
echo "Removing old Docker packages..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
    sudo apt-get remove -y $pkg 2>/dev/null || true
done

# Add Docker's official GPG key:
echo "Setting up Docker repository..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# Create keyrings directory
sudo install -m 0755 -d /etc/apt/keyrings

# Detect OS and set appropriate GPG key URL
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu)
            GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
            REPO_URL="https://download.docker.com/linux/ubuntu"
            ;;
        debian)
            GPG_URL="https://download.docker.com/linux/debian/gpg"
            REPO_URL="https://download.docker.com/linux/debian"
            ;;
        *)
            echo "Unsupported OS: $ID"
            exit 1
            ;;
    esac
else
    echo "Cannot detect OS. /etc/os-release not found."
    exit 1
fi

# Download and install GPG key
sudo curl -fsSL "$GPG_URL" -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $REPO_URL \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt-get update

# Install Docker packages
echo "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (avoid using sudo with docker)
echo "Adding user $USERNAME to docker group..."
sudo usermod -aG docker "$USERNAME"

# Enable and start Docker service
echo "Enabling Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Configure Docker daemon for better security and performance
echo "Configuring Docker daemon..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "userland-proxy": false,
  "experimental": false,
  "live-restore": true
}
EOF

# Restart Docker to apply configuration
sudo systemctl restart docker

# Verify installation
echo "Verifying Docker installation..."
sudo docker --version
sudo docker compose version

# Test Docker with hello-world (optional)
echo "Testing Docker installation..."
if sudo docker run --rm hello-world >/dev/null 2>&1; then
    echo "✅ Docker test successful!"
else
    echo "⚠️  Docker test failed, but installation may still be working"
fi

# Create useful Docker aliases and functions
echo "Setting up Docker aliases..."
cat >> ~/.bashrc << 'EOF'

# Docker aliases
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dcp='docker compose'
alias dcup='docker compose up -d'
alias dcdown='docker compose down'
alias dclogs='docker compose logs -f'

# Docker cleanup function
dcleanup() {
    echo "Cleaning up Docker..."
    docker system prune -f
    docker volume prune -f
    docker network prune -f
}
EOF

echo ""
echo "🐳 Docker installation completed successfully!"
echo ""
echo "Important notes:"
echo "1. User '$USERNAME' has been added to the docker group"
echo "2. You may need to log out and back in for group changes to take effect"
echo "3. Or run: newgrp docker"
echo "4. Docker aliases have been added to ~/.bashrc"
echo "5. Use 'dcleanup' function to clean up unused Docker resources"
echo ""
echo "Test your installation with:"
echo "  docker --version"
echo "  docker run hello-world"
echo ""
echo "For Docker Compose:"
echo "  docker compose version"