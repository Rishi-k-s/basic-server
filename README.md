# Server Setup Scripts

Collection of bash scripts to automate the initial setup of a Linux server with essential security configurations and Docker installation.

## Scripts

- **`serversetup.sh`** - Basic server setup with security hardening
- **`dockerinit.sh`** - Docker installation and configuration

## Features

### Server Setup (`serversetup.sh`)
- Creates a new user with sudo privileges
- Sets up SSH key authentication for the new user
- Updates system packages
- Installs essential packages (ufw, fail2ban, htop, curl, wget, git, unzip)
- Configures UFW firewall with SSH access
- Sets up and starts Fail2Ban for intrusion prevention
- SSH hardening (disables password auth, root login)
- Swap file configuration (2GB)
- System monitoring tools

### Docker Setup (`dockerinit.sh`)
- Removes old Docker packages
- Installs official Docker CE from Docker repository
- Supports both Ubuntu and Debian
- Adds user to docker group
- Configures Docker daemon for security and performance
- Sets up useful Docker aliases and cleanup functions
- Includes Docker Compose

## Prerequisites

- Root or sudo access on the target server
- SSH keys already set up in `~/.ssh/authorized_keys` (optional but recommended)
- Ubuntu/Debian-based Linux distribution

## Usage

### Server Setup Script

1. Make the script executable:
   ```bash
   chmod +x serversetup.sh
   ```

2. Run the script with a username parameter:
   ```bash
   ./serversetup.sh <username>
   ```

   Example:
   ```bash
   ./serversetup.sh john
   ```

### Docker Installation Script

1. Make the script executable:
   ```bash
   chmod +x dockerinit.sh
   ```

2. Run the script (optionally with a username parameter):
   ```bash
   ./dockerinit.sh [username]
   ```

   Examples:
   ```bash
   ./dockerinit.sh          # Uses current user
   ./dockerinit.sh john     # Adds 'john' to docker group
   ```

## Complete Server Setup

For a complete server setup with Docker, run both scripts:

```bash
# First set up the server
./serversetup.sh myuser

# Then install Docker
./dockerinit.sh myuser
```

## What the Scripts Do

### Server Setup Script (`serversetup.sh`)

#### 1. User Management
- Creates a new user account with the provided username
- Adds the user to the sudo group for administrative privileges

#### 2. SSH Configuration
- Creates `.ssh` directory for the new user
- Copies existing SSH authorized keys to the new user (if available)
- Sets proper permissions (700 for `.ssh`, 600 for `authorized_keys`)
- Hardens SSH configuration (disables password auth, root login, X11 forwarding)

#### 3. System Updates
- Updates package lists
- Upgrades all installed packages to latest versions

#### 4. Package Installation
- **ufw**: Uncomplicated Firewall for easy firewall management
- **fail2ban**: Intrusion prevention system
- **htop**: Interactive process viewer
- **curl**: Command-line tool for transferring data
- **wget**: Network downloader
- **git**: Version control system
- **unzip**: Archive extraction utility

#### 5. Security Configuration
- Configures UFW firewall (deny incoming, allow outgoing, allow SSH/HTTP/HTTPS)
- Enables UFW firewall
- Configures and starts Fail2Ban with custom SSH jail
- Creates system monitoring script (`sysinfo` command)

#### 6. System Optimization
- Creates 2GB swap file with low swappiness (10)
- Configures proper swap persistence

### Docker Installation Script (`dockerinit.sh`)

#### 1. Cleanup and Preparation
- Removes old/conflicting Docker packages
- Updates system packages
- Installs prerequisites (ca-certificates, curl)

#### 2. Repository Setup
- Detects OS (Ubuntu/Debian) automatically
- Downloads and installs Docker's official GPG key
- Adds Docker's official repository

#### 3. Docker Installation
- Installs Docker CE, CLI, containerd, buildx, and compose plugins
- Adds specified user to docker group (no more sudo needed)
- Enables and starts Docker service

#### 4. Configuration and Optimization
- Configures Docker daemon with:
  - Log rotation (10MB max, 3 files)
  - Overlay2 storage driver
  - Live restore capability
  - Security optimizations

#### 5. Testing and Setup
- Verifies installation with version checks
- Runs hello-world container test
- Sets up useful Docker aliases:
  - `dps` - docker ps
  - `dpsa` - docker ps -a
  - `di` - docker images
  - `dcp` - docker compose
  - `dcup` - docker compose up -d
  - `dcdown` - docker compose down
  - `dclogs` - docker compose logs -f
  - `dcleanup` - cleanup function for unused resources

## Security Notes

### Server Setup
- SSH password authentication is disabled (key-based auth only)
- Root login via SSH is disabled
- UFW firewall blocks all incoming except SSH, HTTP, HTTPS
- Fail2Ban prevents brute force attacks with 1-hour bans
- New user has sudo privileges - ensure you trust this user
- SSH keys must be properly configured before running

### Docker Setup
- Docker daemon is configured with security best practices
- User is added to docker group (no sudo needed for docker commands)
- Log rotation prevents disk space issues
- Live restore keeps containers running during daemon updates

## Customization

### Server Setup Script
- Install additional packages by adding them to the `apt install` line
- Configure additional UFW rules for specific services
- Customize Fail2Ban jail settings in the jail.local section
- Modify swap file size (default: 2GB)
- Add custom system monitoring commands to the `sysinfo` script

### Docker Installation Script
- Modify Docker daemon configuration in `/etc/docker/daemon.json`
- Add custom Docker aliases to the aliases section
- Change log rotation settings (default: 10MB, 3 files)
- Customize the cleanup function for different needs

## Troubleshooting

### Server Setup Issues

1. **"Could not copy SSH keys" warning**
   - This occurs if `~/.ssh/authorized_keys` doesn't exist
   - You can manually set up SSH keys later

2. **Permission denied errors**  
   - Ensure you're running the script with sudo privileges
   - Check that the script is executable (`chmod +x serversetup.sh`)

3. **Package installation failures**
   - Ensure internet connectivity
   - Try running `sudo apt update` manually first

4. **SSH connection issues after setup**
   - Make sure SSH keys are properly configured
   - Test connection before logging out of current session
   - Use `ssh -v username@server-ip` for verbose debugging

### Docker Installation Issues

1. **"Unsupported OS" error**
   - Currently supports Ubuntu and Debian only
   - Check `/etc/os-release` for your OS identification

2. **Docker group permissions**
   - Log out and back in after installation
   - Or run `newgrp docker` to refresh group membership

3. **Docker test fails but installation succeeds**
   - This is normal and doesn't indicate a problem
   - Test manually with `docker run hello-world`

4. **Repository/GPG key errors**
   - Check internet connectivity
   - Verify DNS resolution works
   - Try running the script again (it's safe to re-run)

### Verification

After running the scripts, verify the setup:

#### Server Setup Verification
```bash
# Check if new user exists
id <username>

# Check UFW status
sudo ufw status

# Check Fail2Ban status
sudo systemctl status fail2ban

# Test SSH access with new user
ssh <username>@<server-ip>

# Check system info
sysinfo
```

#### Docker Installation Verification
```bash
# Check Docker version
docker --version

# Check Docker Compose version  
docker compose version

# Test Docker functionality
docker run hello-world

# Check if user is in docker group
groups

# Test Docker aliases (after reloading shell)
dps
di
```

## License

These scripts are provided as-is for educational and administrative purposes. Use at your own risk.

## Contributing

Feel free to submit issues or pull requests to improve these scripts.
