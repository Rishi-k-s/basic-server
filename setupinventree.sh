#!/bin/bash

# InvenTree Docker Setup Script
# This script sets up InvenTree using Docker Compose

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
INVENTREE_DIR="$HOME/inventree-docker"
INVENTREE_DATA_DIR="$HOME/inventree-data"
INVENTREE_ADMIN_USER="tinkerhub"
INVENTREE_ADMIN_PASSWORD="tinkerhub@ts"
INVENTREE_ADMIN_EMAIL="admin@tinkerhub.com"

# Server IP will be set via command line arguments (required)
SERVER_IP=""
INVENTREE_SITE_URL=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to parse command line arguments
parse_arguments() {
    COMMAND=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            --ip=*)
                SERVER_IP="${1#*=}"
                INVENTREE_SITE_URL="http://${SERVER_IP}:8000"
                shift
                ;;
            --ip)
                SERVER_IP="$2"
                INVENTREE_SITE_URL="http://${SERVER_IP}:8000"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            start|up|stop|down|update|logs|status)
                COMMAND="$1"
                shift
                ;;
            *)
                if [[ -z "$COMMAND" ]]; then
                    print_error "Unknown option: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Check if IP is provided for commands that need it
    if [[ -z "$SERVER_IP" && ("$COMMAND" == "" || "$COMMAND" == "start" || "$COMMAND" == "up" || "$COMMAND" == "update") ]]; then
        print_error "Server IP address is required!"
        echo
        show_help
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "InvenTree Docker Setup Script"
    echo
    echo "Usage: $0 --ip=IP_ADDRESS [COMMAND]"
    echo
    echo "REQUIRED OPTIONS:"
    echo "  --ip=IP_ADDRESS    Set the server IP address (REQUIRED)"
    echo "  --ip IP_ADDRESS    Set the server IP address (alternative syntax)"
    echo
    echo "OTHER OPTIONS:"
    echo "  -h, --help         Show this help message"
    echo
    echo "COMMANDS:"
    echo "  start, up          Start InvenTree services"
    echo "  stop, down         Stop InvenTree services"
    echo "  update             Update InvenTree to latest version"
    echo "  logs               View InvenTree logs"
    echo "  status             Show service status"
    echo "  (no command)       Run full setup"
    echo
    echo "EXAMPLES:"
    echo "  $0 --ip=192.168.1.100        # Run setup with IP address"
    echo "  $0 --ip 10.0.0.5             # Run setup with IP address (alternative syntax)"
    echo "  $0 --ip=192.168.1.100 start  # Start services with IP address"
    echo "  $0 stop                      # Stop services (no IP needed)"
    echo "  $0 logs                      # View logs (no IP needed)"
    echo "  $0 --help                    # Show this help"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! command_exists wget; then
        print_error "wget is not installed. Please install wget first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Setup InvenTree directory and files
setup_inventree() {
    print_status "Setting up InvenTree directory..."
    
    # Create directory if it doesn't exist
    if [ ! -d "$INVENTREE_DIR" ]; then
        mkdir -p "$INVENTREE_DIR"
        print_success "Created InvenTree directory: $INVENTREE_DIR"
    else
        print_warning "InvenTree directory already exists: $INVENTREE_DIR"
    fi
    
    cd "$INVENTREE_DIR"
    
    # Download required files
    print_status "Downloading InvenTree Docker configuration files..."
    
    if [ ! -f "docker-compose.yml" ]; then
        wget -q https://raw.githubusercontent.com/inventree/inventree/stable/contrib/container/docker-compose.yml
        print_success "Downloaded docker-compose.yml"
    else
        print_warning "docker-compose.yml already exists"
    fi
    
    if [ ! -f ".env" ]; then
        wget -q https://raw.githubusercontent.com/inventree/inventree/stable/contrib/container/.env
        print_success "Downloaded .env file"
    else
        print_warning ".env file already exists"
    fi
    
    if [ ! -f "Caddyfile" ]; then
        wget -q https://raw.githubusercontent.com/inventree/inventree/stable/contrib/container/Caddyfile
        print_success "Downloaded Caddyfile"
    else
        print_warning "Caddyfile already exists"
    fi
}

# Configure environment variables
configure_environment() {
    print_status "Configuring environment variables..."
    
    # Create data directory
    mkdir -p "$INVENTREE_DATA_DIR"
    print_success "Created data directory: $INVENTREE_DATA_DIR"
    
    # Function to update or add environment variable in .env file
    update_env_var() {
        local var_name="$1"
        local var_value="$2"
        local env_file=".env"
        
        if grep -q "^${var_name}=" "$env_file" 2>/dev/null; then
            # Variable exists, update it
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS sed syntax
                sed -i '' "s|^${var_name}=.*|${var_name}=${var_value}|" "$env_file"
            else
                # Linux sed syntax
                sed -i "s|^${var_name}=.*|${var_name}=${var_value}|" "$env_file"
            fi
        else
            # Variable doesn't exist, add it
            echo "${var_name}=${var_value}" >> "$env_file"
        fi
    }
    
    # Update or add each configuration variable
    update_env_var "INVENTREE_EXT_VOLUME" "$INVENTREE_DATA_DIR"
    update_env_var "INVENTREE_SITE_URL" "$INVENTREE_SITE_URL"
    update_env_var "INVENTREE_ADMIN_USER" "$INVENTREE_ADMIN_USER"
    update_env_var "INVENTREE_ADMIN_PASSWORD" "$INVENTREE_ADMIN_PASSWORD"
    update_env_var "INVENTREE_ADMIN_EMAIL" "$INVENTREE_ADMIN_EMAIL"
    
    print_success "Environment configuration updated"
}

# Setup firewall rules
setup_firewall() {
    print_status "Setting up firewall rules..."
    
    if command_exists ufw; then
        # Allow port 8000 for HTTP
        sudo ufw allow 8000/tcp >/dev/null 2>&1 || true
        print_success "Allowed port 8000 (HTTP) through firewall"
        
        # Allow port 443 for HTTPS (if needed later)
        sudo ufw allow 443/tcp >/dev/null 2>&1 || true
        print_success "Allowed port 443 (HTTPS) through firewall"
    else
        print_warning "UFW not found, skipping firewall configuration"
    fi
}

# Initial setup and database update
initial_setup() {
    print_status "Performing initial InvenTree setup..."
    
    # Pull images
    docker compose pull
    print_success "Docker images pulled"
    
    # Run initial database setup
    print_status "Initializing database (this may take a few minutes)..."
    docker compose run --rm inventree-server invoke update
    print_success "Database initialized successfully"
}

# Start InvenTree services
start_services() {
    print_status "Starting InvenTree services..."
    docker compose up -d
    print_success "InvenTree services started"
    
    # Wait a moment for services to start
    sleep 5
    
    # Check if services are running
    if docker compose ps | grep -q "Up"; then
        print_success "InvenTree is now running!"
        echo
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}  InvenTree Setup Complete!${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo
        echo -e "${BLUE}Access InvenTree at:${NC} $INVENTREE_SITE_URL"
        echo -e "${BLUE}Admin Username:${NC} $INVENTREE_ADMIN_USER"
        echo -e "${BLUE}Admin Password:${NC} $INVENTREE_ADMIN_PASSWORD"
        echo
        echo -e "${YELLOW}Useful commands:${NC}"
        echo -e "  View logs:     ${BLUE}docker compose logs -f${NC}"
        echo -e "  Stop services: ${BLUE}docker compose down${NC}"
        echo -e "  Start services:${BLUE}docker compose up -d${NC}"
        echo -e "  Update:        ${BLUE}docker compose pull && docker compose run --rm inventree-server invoke update && docker compose up -d${NC}"
        echo
    else
        print_error "Some services failed to start. Check logs with: docker compose logs"
        exit 1
    fi
}

# Main execution
main() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  InvenTree Docker Setup Script${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo
    echo -e "${BLUE}Server IP:${NC} $SERVER_IP"
    echo -e "${BLUE}InvenTree URL:${NC} $INVENTREE_SITE_URL"
    echo
    
    check_prerequisites
    setup_inventree
    configure_environment
    setup_firewall
    initial_setup
    start_services
}

# Parse arguments first
parse_arguments "$@"

# Handle script commands
case "${COMMAND:-}" in
    "start"|"up")
        print_status "Using server IP: $SERVER_IP"
        cd "$INVENTREE_DIR" && docker compose up -d
        print_success "InvenTree services started"
        ;;
    "stop"|"down")
        cd "$INVENTREE_DIR" && docker compose down
        print_success "InvenTree services stopped"
        ;;
    "update")
        print_status "Using server IP: $SERVER_IP"
        cd "$INVENTREE_DIR"
        print_status "Updating InvenTree..."
        docker compose down
        docker compose pull
        docker compose run --rm inventree-server invoke update
        docker compose up -d
        print_success "InvenTree updated successfully"
        ;;
    "logs")
        cd "$INVENTREE_DIR" && docker compose logs -f
        ;;
    "status")
        cd "$INVENTREE_DIR" && docker compose ps
        ;;
    "")
        main
        ;;
esac