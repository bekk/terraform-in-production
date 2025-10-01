# macOS-Specific Workshop Notes

This document provides macOS-specific guidance for the Terraform workshop.

## Installation on macOS

### Quick Installation

**Recommended: Using Homebrew**

```bash
# Install Homebrew if needed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install workshop tools
brew install terraform
brew install --cask google-cloud-sdk
brew install git  # Usually pre-installed, but gets latest version
```

**Alternative:** Follow official guides at [Terraform Install](https://developer.hashicorp.com/terraform/install) and [Google Cloud SDK Install](https://cloud.google.com/sdk/docs/install#mac)

### Authentication Setup

#### Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/) and log in with your Google account.
2. Note the project ID you'll be using for the workshop.

#### gcloud Authentication
In Terminal:

```bash
# Log in to Google Cloud
gcloud auth login

# Set the workshop project (if not prompted during login)
gcloud config set project cloud-labs-workshop-42clws

# Set up application default credentials for Terraform
gcloud auth application-default login

# Verify your setup
gcloud config list
```

### Setup Verification

Run the setup verification script:

```bash
./verify-setup.sh
```

This script will check that you have all required tools installed and properly configured.

## Terminal Environment

macOS uses **zsh** as the default shell (since macOS 10.15). The workshop commands work with the default zsh configuration.

### Built-in Terminal

**Terminal.app** (built-in) works perfectly for the workshop. **iTerm2** is a popular alternative with additional features.

### Common macOS Issues and Solutions

**Common Issues and Solutions:**

- **"terraform: command not found"**: Ensure Terraform is in your PATH. Restart your terminal after installation.

- **"gcloud: command not found"**: Ensure Google Cloud SDK is in your PATH. You may need to restart your terminal or reinstall the SDK.

- **"gcloud auth list shows no accounts"**: Run `gcloud auth login` to authenticate.

- **"Permission denied" when accessing project**: Ensure you have the necessary IAM roles in the project. Contact workshop facilitators if using the provided project.

- **"Application Default Credentials not found"**: Run `gcloud auth application-default login` to set up credentials for Terraform.

- **Terraform provider errors**: Make sure you're in the `infra/` directory and have run `terraform init`.

### Homebrew Issues

```bash
# Update Homebrew
brew update

# Fix common issues
brew doctor
```

### PATH Issues

If commands aren't found after installation:

```bash
# Check your PATH
echo $PATH

# For Apple Silicon Macs, ensure Homebrew is in PATH
export PATH="/opt/homebrew/bin:$PATH"
```

### Google Cloud SDK Issues

```bash
# If gcloud not found after Homebrew installation
gcloud init

# For manual installation, source the SDK
source ~/google-cloud-sdk/path.zsh.inc
```

## Text Editor Setup

### Recommended: VS Code

[Visual Studio Code](https://code.visualstudio.com/) is recommended for the workshop:

```bash
# Install VS Code via Homebrew
brew install --cask visual-studio-code

# Install Terraform extension
code --install-extension HashiCorp.terraform
```

### Alternative Editors

Terraform-specific plugins are available for:

- **(Neo)Vim:** [vim-terraform](https://github.com/hashivim/vim-terraform)
- **IntelliJ IDEA:** [Terraform and HCL plugin](https://plugins.jetbrains.com/plugin/7808-terraform-and-hcl)
- **Built-in editors:** TextEdit, `vim`, or your preferred editor

## Quick Reference

### Common Commands

```bash
# Navigation and files
cd directory              # Change directory
ls -la                    # List files
vim filename.tf           # Edit with vim
code filename.tf          # Edit with VS Code

# System information
sw_vers                   # macOS version
```

### Keyboard Shortcuts

- **Cmd+T** - New terminal tab
- **Cmd+K** - Clear terminal screen
- **Cmd+C/V** - Copy/Paste

### Getting Help

```bash
terraform --help
gcloud --help
man terraform            # Manual pages
brew --help              # Homebrew help
```

If you encounter macOS-specific issues during the workshop, try the solutions above or ask workshop facilitators for help.
