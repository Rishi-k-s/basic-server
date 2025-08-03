# Server Setup Script

A bash script to automate the initial setup of a Linux server with essential security configurations and tools.

## Features

- Creates a new user with sudo privileges
- Sets up SSH key authentication for the new user
- Updates system packages
- Installs essential packages (ufw, fail2ban, htop, curl, wget, git, unzip)
- Configures UFW firewall with SSH access
- Sets up and starts Fail2Ban for intrusion prevention

## Prerequisites

- Root or sudo access on the target server
- SSH keys already set up in `~/.ssh/authorized_keys` (optional but recommended)
- Ubuntu/Debian-based Linux distribution

## Usage

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

## What the Script Does

### 1. User Management
- Creates a new user account with the provided username
- Adds the user to the sudo group for administrative privileges

### 2. SSH Configuration
- Creates `.ssh` directory for the new user
- Copies existing SSH authorized keys to the new user (if available)
- Sets proper permissions (700 for `.ssh`, 600 for `authorized_keys`)

### 3. System Updates
- Updates package lists
- Upgrades all installed packages to latest versions

### 4. Package Installation
- **ufw**: Uncomplicated Firewall for easy firewall management
- **fail2ban**: Intrusion prevention system
- **htop**: Interactive process viewer
- **curl**: Command-line tool for transferring data
- **wget**: Network downloader
- **git**: Version control system
- **unzip**: Archive extraction utility

### 5. Security Configuration
- Configures UFW firewall to allow SSH connections
- Enables UFW firewall
- Enables and starts Fail2Ban service

## Security Notes

- The script allows SSH access through the firewall by default
- Fail2Ban is configured with default settings to prevent brute force attacks
- SSH key authentication is set up if keys are available
- The new user has sudo privileges - ensure you trust this user

## Customization

You can modify the script to:
- Install additional packages by adding them to the `apt install` line
- Configure additional UFW rules
- Customize Fail2Ban configuration by creating custom jail files

## Troubleshooting

### Common Issues

1. **"Could not copy SSH keys" warning**
   - This occurs if `~/.ssh/authorized_keys` doesn't exist
   - You can manually set up SSH keys later

2. **Permission denied errors**
   - Ensure you're running the script with sudo privileges
   - Check that the script is executable (`chmod +x serversetup.sh`)

3. **Package installation failures**
   - Ensure internet connectivity
   - Try running `sudo apt update` manually first

### Verification

After running the script, verify the setup:

```bash
# Check if new user exists
id <username>

# Check UFW status
sudo ufw status

# Check Fail2Ban status
sudo systemctl status fail2ban

# Test SSH access with new user
ssh <username>@<server-ip>
```

## License

This script is provided as-is for educational and administrative purposes. Use at your own risk.

## Contributing

Feel free to submit issues or pull requests to improve this script.
