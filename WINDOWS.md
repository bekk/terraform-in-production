# Windows-Specific Workshop Notes

This document provides Windows-specific guidance for the Terraform workshop.

## Installation on Windows

### Quick Installation

**Recommended: Using Chocolatey**

```powershell
# Install Chocolatey if needed (run as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install workshop tools
choco install terraform
choco install gcloudsdk
choco install git
```

**Alternative:** Follow official guides at [Terraform Install](https://developer.hashicorp.com/terraform/install) and [Google Cloud SDK Install](https://cloud.google.com/sdk/docs/install#windows)

### Authentication Setup

#### Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/) and log in with your Google account.
2. Note the project ID you'll be using for the workshop.

#### gcloud Authentication
In PowerShell or Command Prompt:

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

```powershell
.\verify-setup.ps1
```

This script will check that you have all required tools installed and properly configured.

## Terminal Options for Windows Users

**PowerShell** (recommended) is the modern Windows shell and works great for the workshop. You can also use Command Prompt or Git Bash if you prefer.

### Getting Started with PowerShell

If you're new to PowerShell:

- Use Tab for auto-completion
- Use ↑/↓ arrows for command history
- Right-click to paste
- Use `cls` to clear screen

### Common Windows Issues and Solutions

**Common Issues and Solutions:**

- **"terraform: command not found"**: Ensure Terraform is in your PATH. Restart your terminal after installation.

- **"gcloud: command not found"**: Ensure Google Cloud SDK is in your PATH. You may need to restart your terminal or reinstall the SDK.

- **"gcloud auth list shows no accounts"**: Run `gcloud auth login` to authenticate.

- **"Permission denied" when accessing project**: Ensure you have the necessary IAM roles in the project. Contact workshop facilitators if using the provided project.

- **"Application Default Credentials not found"**: Run `gcloud auth application-default login` to set up credentials for Terraform.

- **Terraform provider errors**: Make sure you're in the `infra/` directory and have run `terraform init`.

### PowerShell Execution Policy

If you get execution policy errors:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### PATH Issues

If commands aren't found after installation:

1. Restart your terminal
1. Check PATH: `echo $env:PATH` (PowerShell)
1. Reinstall tools if needed

## Text Editor Setup

### Recommended: VS Code

[Visual Studio Code](https://code.visualstudio.com/) is recommended for the workshop:

```powershell
# Install VS Code via Chocolatey
choco install vscode

# Install Terraform extension
code --install-extension HashiCorp.terraform
```

### Alternative Editors

Terraform-specific plugins are available for: (Neo)Vim, [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/7808-terraform-and-hcl) and more.

## Quick Reference

### Common Commands

```powershell
# Navigation and files  
cd infra                  # Change directory
ls                        # List files (or dir)
notepad filename.tf       # Edit with Notepad
code filename.tf          # Edit with VS Code

# System information
Get-ComputerInfo          # System details
```

### Getting Help

```powershell
terraform --help
gcloud --help
Get-Help                  # PowerShell help system
```

If you encounter Windows-specific issues during the workshop, try the solutions above or ask workshop facilitators for help.
