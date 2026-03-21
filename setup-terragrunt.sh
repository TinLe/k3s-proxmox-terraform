#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}K3s on Proxmox Setup (Terragrunt + OpenTofu)${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install with brew
install_with_brew() {
    if command_exists brew; then
        echo -e "${YELLOW}Installing $1 with Homebrew...${NC}"
        brew install "$1"
        return 0
    fi
    return 1
}

# Check OS
echo -e "${YELLOW}Checking system...${NC}"
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac
echo -e "${GREEN}✓ Detected: $MACHINE${NC}"
echo ""

# Check for OpenTofu
echo -e "${YELLOW}Checking for OpenTofu...${NC}"
if command_exists tofu; then
    TOFU_VERSION=$(tofu version | head -n1)
    echo -e "${GREEN}✓ OpenTofu found: $TOFU_VERSION${NC}"
elif command_exists terraform; then
    TF_VERSION=$(terraform version | head -n1)
    echo -e "${YELLOW}⚠ Terraform found: $TF_VERSION${NC}"
    echo -e "${YELLOW}  OpenTofu is recommended. Install from: https://opentofu.org/docs/intro/install/${NC}"
else
    echo -e "${RED}✗ Neither OpenTofu nor Terraform found${NC}"
    echo ""
    echo "Installing OpenTofu..."
    
    if [ "$MACHINE" = "Mac" ]; then
        if install_with_brew opentofu; then
            echo -e "${GREEN}✓ OpenTofu installed${NC}"
        else
            echo -e "${RED}Failed to install OpenTofu${NC}"
            echo "Please install manually: https://opentofu.org/docs/intro/install/"
            exit 1
        fi
    elif [ "$MACHINE" = "Linux" ]; then
        echo "Run: curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | sh"
        exit 1
    fi
fi
echo ""

# Check for Terragrunt
echo -e "${YELLOW}Checking for Terragrunt...${NC}"
if command_exists terragrunt; then
    TG_VERSION=$(terragrunt --version | head -n1)
    echo -e "${GREEN}✓ Terragrunt found: $TG_VERSION${NC}"
else
    echo -e "${RED}✗ Terragrunt not found${NC}"
    echo ""
    echo "Installing Terragrunt..."
    
    if [ "$MACHINE" = "Mac" ]; then
        if install_with_brew terragrunt; then
            echo -e "${GREEN}✓ Terragrunt installed${NC}"
        else
            echo -e "${RED}Failed to install Terragrunt${NC}"
            echo "Please install manually: https://terragrunt.gruntwork.io/docs/getting-started/install/"
            exit 1
        fi
    elif [ "$MACHINE" = "Linux" ]; then
        echo "Downloading Terragrunt..."
        TG_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d '"' -f 4)
        curl -L "https://github.com/gruntwork-io/terragrunt/releases/download/${TG_VERSION}/terragrunt_linux_amd64" -o /tmp/terragrunt
        chmod +x /tmp/terragrunt
        sudo mv /tmp/terragrunt /usr/local/bin/terragrunt
        echo -e "${GREEN}✓ Terragrunt installed${NC}"
    fi
fi
echo ""

# Check for uv
echo -e "${YELLOW}Checking for uv...${NC}"
if command_exists uv; then
    UV_VERSION=$(uv --version)
    echo -e "${GREEN}✓ uv found: $UV_VERSION${NC}"
else
    echo -e "${RED}✗ uv not found${NC}"
    echo ""
    echo "Installing uv..."
    
    if [ "$MACHINE" = "Mac" ]; then
        if install_with_brew uv; then
            echo -e "${GREEN}✓ uv installed${NC}"
        else
            echo -e "${YELLOW}Installing via curl...${NC}"
            curl -LsSf https://astral.sh/uv/install.sh | sh
            echo -e "${GREEN}✓ uv installed${NC}"
        fi
    elif [ "$MACHINE" = "Linux" ]; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        echo -e "${GREEN}✓ uv installed${NC}"
    fi
fi
echo ""

# Check for Ansible (will be installed via uv)
echo -e "${YELLOW}Checking for Ansible...${NC}"
if command_exists ansible; then
    ANSIBLE_VERSION=$(ansible --version | head -n1)
    echo -e "${GREEN}✓ Ansible found: $ANSIBLE_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ Ansible not found${NC}"
    echo "  Will be installed via uv in Python virtual environment"
fi
echo ""

# Check for jq
echo -e "${YELLOW}Checking for jq...${NC}"
if command_exists jq; then
    echo -e "${GREEN}✓ jq found${NC}"
else
    echo -e "${RED}✗ jq not found${NC}"
    echo ""
    echo "Installing jq..."
    
    if [ "$MACHINE" = "Mac" ]; then
        if install_with_brew jq; then
            echo -e "${GREEN}✓ jq installed${NC}"
        else
            echo -e "${RED}Failed to install jq${NC}"
            exit 1
        fi
    elif [ "$MACHINE" = "Linux" ]; then
        sudo apt-get update && sudo apt-get install -y jq
        echo -e "${GREEN}✓ jq installed${NC}"
    fi
fi
echo ""

# Check for SSH key
echo -e "${YELLOW}Checking for SSH key...${NC}"
if [ -f ~/.ssh/id_ed25519.pub ]; then
    echo -e "${GREEN}✓ SSH key found: ~/.ssh/id_ed25519.pub${NC}"
    SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)
elif [ -f ~/.ssh/id_rsa.pub ]; then
    echo -e "${GREEN}✓ SSH key found: ~/.ssh/id_rsa.pub${NC}"
    SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
else
    echo -e "${RED}✗ No SSH key found${NC}"
    echo ""
    read -p "Generate SSH key now? (yes/no): " generate_key
    if [ "$generate_key" = "yes" ]; then
        ssh-keygen -t ed25519 -C "k3s-proxmox" -f ~/.ssh/id_ed25519 -N ""
        echo -e "${GREEN}✓ SSH key generated${NC}"
        SSH_KEY=$(cat ~/.ssh/id_ed25519.pub)
    else
        echo "Please generate SSH key manually: ssh-keygen -t ed25519"
        exit 1
    fi
fi
echo ""

# Check for .envrc file
echo -e "${YELLOW}Checking for .envrc file...${NC}"
if [ -f .envrc ]; then
    echo -e "${GREEN}✓ .envrc file exists${NC}"
    echo -e "${YELLOW}  Please verify your configuration${NC}"
else
    echo -e "${YELLOW}⚠ .envrc file not found${NC}"
    echo ""
    read -p "Create .envrc file now? (yes/no): " create_envrc
    if [ "$create_envrc" = "yes" ]; then
        cp .envrc.example .envrc
        
        # Try to populate with detected values
        if [ -n "$SSH_KEY" ]; then
            sed -i.bak "s|ssh-ed25519 YOUR_PUBLIC_KEY_HERE|$SSH_KEY|g" .envrc
            rm .envrc.bak 2>/dev/null || true
        fi
        
        echo -e "${GREEN}✓ .envrc file created${NC}"
        echo -e "${YELLOW}  Please edit .envrc and add your Proxmox credentials:${NC}"
        echo -e "${YELLOW}    - PROXMOX_API_URL${NC}"
        echo -e "${YELLOW}    - PROXMOX_API_TOKEN_ID${NC}"
        echo -e "${YELLOW}    - PROXMOX_API_TOKEN_SECRET${NC}"
        echo ""
        read -p "Press Enter to edit .envrc now..."
        ${EDITOR:-nano} .envrc
    else
        echo "Please create .envrc manually from .envrc.example"
        exit 1
    fi
fi
echo ""

# Check for direnv (optional)
echo -e "${YELLOW}Checking for direnv (optional)...${NC}"
if command_exists direnv; then
    echo -e "${GREEN}✓ direnv found${NC}"
    echo -e "${YELLOW}  Run 'direnv allow' to automatically load environment variables${NC}"
else
    echo -e "${YELLOW}⚠ direnv not found (optional)${NC}"
    echo "  Install direnv for automatic environment loading: brew install direnv"
    echo "  Or manually load with: source .envrc"
fi
echo ""

# Setup Python virtual environment with uv
echo -e "${YELLOW}Setting up Python virtual environment with uv...${NC}"
if [ -f requirements.txt ]; then
    # Initialize pyproject.toml if it doesn't exist
    if [ ! -f pyproject.toml ]; then
        uv init --no-readme --no-workspace
    fi
    
    # Create virtual environment
    if [ ! -d .venv ]; then
        uv venv --seed
    fi
    
    # Activate and install dependencies
    source .venv/bin/activate
    uv pip install -r requirements.txt
    
    # Install Ansible Galaxy requirements
    if [ -f requirements.yml ]; then
        .venv/bin/ansible-galaxy install -r requirements.yml
    fi
    
    deactivate
    
    echo -e "${GREEN}✓ Python virtual environment created with uv${NC}"
    echo -e "${GREEN}✓ Ansible and dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠ requirements.txt not found, skipping venv setup${NC}"
fi
echo ""

# Make scripts executable
echo -e "${YELLOW}Making scripts executable...${NC}"
chmod +x deploy.sh
echo -e "${GREEN}✓ Scripts are executable${NC}"
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Prerequisites installed:${NC}"
echo "  ✓ OpenTofu/Terraform"
echo "  ✓ Terragrunt"
echo "  ✓ Ansible"
echo "  ✓ jq"
echo "  ✓ SSH key"
echo "  ✓ .envrc file"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Load environment variables:"
echo "     source .envrc"
echo ""
echo "  2. Verify configuration:"
echo "     echo \$PROXMOX_API_TOKEN_SECRET"
echo ""
echo "  3. Activate Python virtual environment (if needed):"
echo "     source .venv/bin/activate"
echo ""
echo "  4. Deploy cluster:"
echo "     ./deploy.sh dev"
echo ""
echo "  5. Or use Makefile:"
echo "     make plan ENV=dev"
echo "     make apply ENV=dev"
echo ""
echo -e "${YELLOW}For more information, see:${NC}"
echo "  - README.md"
echo "  - docs/README.md"
echo ""
