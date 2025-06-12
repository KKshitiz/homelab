# Homelab Ansible Makefile
# Simple commands to manage your homelab

.PHONY: help setup ping deploy services monitoring backup restore clean

# Default target
help:
	@echo "🏠 Homelab Ansible Management"
	@echo ""
	@echo "Available commands:"
	@echo "  setup      - Initial setup of control machine"
	@echo "  ping       - Test connection to homelab servers"
	@echo "  deploy     - Full homelab deployment"
	@echo "  services   - Deploy only services"
	@echo "  monitoring - Deploy only monitoring stack"
	@echo "  backup     - Backup homelab data"
	@echo "  restore    - Restore from backup"
	@echo "  update     - Update all services"
	@echo "  restart    - Restart all services"
	@echo "  logs       - View service logs"
	@echo "  clean      - Clean unused Docker resources"
	@echo ""

# Initial setup
setup:
	@echo "🚀 Setting up homelab environment..."
	./setup.sh

# Test connectivity
ping:
	@echo "🏓 Testing connection to homelab servers..."
	ansible homelab -m ping

# Full deployment
deploy:
	@echo "🚀 Deploying full homelab stack..."
	ansible-playbook playbooks/site.yml --ask-become-pass

# Deploy only services
services:
	@echo "📦 Deploying services..."
	ansible-playbook playbooks/site.yml --tags services

# Deploy only monitoring
monitoring:
	@echo "📊 Deploying monitoring stack..."
	ansible-playbook playbooks/site.yml --tags monitoring

# Common Docker operations
update:
	@echo "🔄 Updating all services..."
	ansible homelab -m shell -a "cd /opt/homelab && docker-compose pull && docker-compose up -d"

restart:
	@echo "🔄 Restarting all services..."
	ansible homelab -m shell -a "cd /opt/homelab && docker-compose restart"

logs:
	@echo "📋 Viewing service logs..."
	ansible homelab -m shell -a "cd /opt/homelab && docker-compose logs -f --tail=50" -f 5

# Maintenance
backup:
	@echo "💾 Creating backup..."
	ansible-playbook playbooks/backup.yml

restore:
	@echo "🔄 Restoring from backup..."
	ansible-playbook playbooks/restore.yml

clean:
	@echo "🧹 Cleaning unused Docker resources..."
	ansible homelab -m shell -a "docker system prune -af && docker volume prune -f"

# Development helpers
lint:
	@echo "🔍 Linting Ansible playbooks..."
	ansible-lint playbooks/

syntax:
	@echo "✅ Checking syntax..."
	ansible-playbook playbooks/site.yml --syntax-check

dry-run:
	@echo "🔍 Dry run deployment..."
	ansible-playbook playbooks/site.yml --check --diff

# Quick status
status:
	@echo "📊 Service status..."
	ansible homelab -m shell -a "cd /opt/homelab && docker-compose ps"