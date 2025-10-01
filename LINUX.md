# Linux-Specific Workshop Notes

This document provides Linux-specific guidance for the Terraform workshop.

## Installation on Linux

### Quick Installation

Follow the official installation guides for your distribution:

- **Terraform:** [HashiCorp Installation Guide](https://developer.hashicorp.com/terraform/install)
- **Google Cloud SDK:** [Google Cloud SDK Installation](https://cloud.google.com/sdk/docs/install)
- **Git:** Usually pre-installed, or use your package manager (e.g., `sudo apt install git`)

### Package Manager Quick Reference

- **Ubuntu/Debian:** Use `apt` - see [Terraform APT](https://developer.hashicorp.com/terraform/install#ubuntu-debian) and [GCloud APT](https://cloud.google.com/sdk/docs/install#deb)
- **CentOS/RHEL/Fedora:** Use `yum`/`dnf` - see [Terraform YUM](https://developer.hashicorp.com/terraform/install#centos-rhel) and [GCloud YUM](https://cloud.google.com/sdk/docs/install#rpm)
- **Arch Linux:** Use `pacman` or AUR - packages available in repositories

### Authentication Setup

#### Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/) and log in with your Google account.
2. Note the project ID you'll be using for the workshop.

#### gcloud Authentication
In your terminal:

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

Linux uses **bash** as the default shell on most distributions. The workshop commands are designed for bash and work out of the box.

### Terminal Applications

Most Linux distributions include a terminal application. Common ones include GNOME Terminal (Ubuntu), Konsole (KDE), or your distribution's default.

### Common Linux Issues and Solutions

**Common Issues and Solutions:**

- **"terraform: command not found"**: Ensure Terraform is in your PATH. Restart your terminal after installation.

- **"gcloud: command not found"**: Ensure Google Cloud SDK is in your PATH. You may need to restart your terminal or reinstall the SDK.

- **"gcloud auth list shows no accounts"**: Run `gcloud auth login` to authenticate.

- **"Permission denied" when accessing project**: Ensure you have the necessary IAM roles in the project. Contact workshop facilitators if using the provided project.

- **"Application Default Credentials not found"**: Run `gcloud auth application-default login` to set up credentials for Terraform.

- **Terraform provider errors**: Make sure you're in the `infra/` directory and have run `terraform init`.

### PATH Issues

If commands aren't found after installation:

```bash
# Check your PATH
echo $PATH

# Restart your shell
exec -l $SHELL
```

### Google Cloud SDK Issues

If `gcloud` command is not found after installation:

```bash
# Restart your shell
exec -l $SHELL

# Or source the SDK if manually installed
source ~/google-cloud-sdk/path.bash.inc
```

For more help, see the [official troubleshooting guide](https://cloud.google.com/sdk/docs/troubleshooting).

## Text Editor Setup

### Recommended: VS Code

[Visual Studio Code](https://code.visualstudio.com/) is recommended for the workshop.

**Installation:** Follow the [official VS Code Linux installation guide](https://code.visualstudio.com/docs/setup/linux) for your distribution.

**Terraform extension:**
```bash
# Install the Terraform extension
code --install-extension HashiCorp.terraform
```

### Alternative Editors

Terraform-specific plugins are available for: (Neo)Vim, [IntelliJ IDEA](https://plugins.jetbrains.com/plugin/7808-terraform-and-hcl) and more.

## Quick Reference

### Common Commands

```bash
# Navigation and files
cd directory              # Change directory
ls -la                    # List files
vim filename.tf           # Edit with vim
code filename.tf          # Edit with VS Code

# System information
lsb_release -a            # Distribution info
```

### Getting Help

```bash
terraform --help
gcloud --help
man terraform            # Manual pages
```

If you encounter issues during the workshop, try the solutions above or ask workshop facilitators for help.
