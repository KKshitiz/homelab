#!/bin/bash

# Homelab Ansible Setup Script
# This script sets up your control machine and deploys the homelab

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Ubuntu/Debian
if ! command -v apt &> /dev/null; then
    print_error "This script is designed for Ubuntu/Debian systems"
    exit 1
fi

print_status "🚀 Setting up Homelab Ansible Environment"

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python and pip
print_status "Installing Python and pip..."
sudo apt install -y python3 python3-pip python3-venv

# Install Ansible
print_status "Installing Ansible..."
python3 -m pip install --user ansible

# Add local bin to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    export PATH="$HOME/.local/bin:$PATH"
fi

# Install Ansible collections
print_status "Installing Ansible collections..."
ansible-galaxy collection install community.docker
ansible-galaxy collection install community.general

# Check if SSH key exists
if [ ! -f ~/.ssh/id_rsa ]; then
    print_warning "No SSH key found. Generating one..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    print_status "SSH key generated at ~/.ssh/id_rsa"
    print_warning "Don't forget to copy your public key to your server:"
    print_warning "ssh-copy-id ubuntu@YOUR_SERVER_IP"
fi

# Create project directory if it doesn't exist
if [ ! -d "homelab-ansible" ]; then
    print_status "Creating project structure..."
    mkdir -p homelab-ansible/{inventory/group_vars,playbooks,roles/{common,docker,services,monitoring}/{tasks,templates,handlers,files},files/{docker-compose,configs,scripts},templates,vars}
    cd homelab-ansible
    
    # Initialize git repository
    git init
    echo "data/" >> .gitignore
    echo "backups/" >> .gitignore
    echo "*.log" >> .gitignore
    echo ".env" >> .gitignore
    
    print_status "Project structure created!"
else
    cd homelab-ansible
    print_status "Using existing project directory"
fi

# Verify Ansible installation
print_status "Verifying Ansible installation..."
if ansible --version &> /dev/null; then
    print_status "✅ Ansible installed successfully!"
    ansible --version | head -1
else
    print_error "❌ Ansible installation failed"
    exit 1
fi

print_status "🎉 Setup complete!"
echo ""
print_warning "Next steps:"
echo "1. Edit inventory/hosts.yml with your server details"
echo "2. Copy your SSH key to the server: ssh-copy-id ubuntu@YOUR_SERVER_IP"
echo "3. Test connection: ansible homelab -m ping"
echo "4. Deploy homelab: ansible-playbook playbooks/site.yml"
echo ""
print_status "Happy homelabbing! 🏠"