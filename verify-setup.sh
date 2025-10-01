#!/bin/bash

echo "🔍 Verifying workshop prerequisites..."

# Check Terraform installation
if command -v terraform &> /dev/null; then
    echo "✅ Terraform found: $(terraform version -json | jq -r .terraform_version)"
else
    echo "❌ Terraform not found. Please install Terraform CLI."
    echo "   Installation guide: https://developer.hashicorp.com/terraform/install"
    exit 1
fi

# Check gcloud installation
if command -v gcloud &> /dev/null; then
    GCLOUD_VERSION=$(gcloud version --format="value(Google Cloud SDK)" 2>/dev/null | head -n1)
    if [ -n "$GCLOUD_VERSION" ]; then
        echo "✅ Google Cloud SDK found: $GCLOUD_VERSION"
    else
        # Fallback to simple version check
        echo "✅ Google Cloud SDK found: $(gcloud --version | head -n1 | cut -d' ' -f4)"
    fi
else
    echo "❌ gcloud not found. Please install Google Cloud SDK."
    echo "   Installation guide: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check gcloud authentication
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    echo "✅ Authenticated as: $ACTIVE_ACCOUNT"
else
    echo "❌ Not authenticated with gcloud. Please run 'gcloud auth login'"
    exit 1
fi

# Check application default credentials
if gcloud auth application-default print-access-token &> /dev/null; then
    echo "✅ Application Default Credentials configured"
else
    echo "⚠️  Application Default Credentials not configured. Please run 'gcloud auth application-default login'"
    echo "   This is required for Terraform to authenticate with Google Cloud."
fi

# Check project configuration
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -n "$PROJECT_ID" ]; then
    echo "✅ Project configured: $PROJECT_ID"
    
    # Verify project access
    if gcloud projects describe "$PROJECT_ID" &> /dev/null; then
        echo "✅ Project access verified"
    else
        echo "❌ Cannot access project: $PROJECT_ID"
        echo "   Please ensure you have the necessary permissions or set the correct project."
        exit 1
    fi
else
    echo "⚠️  No default project configured. You may need to run:"
    echo "   gcloud config set project YOUR_PROJECT_ID"
fi

# Check if jq is available for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "ℹ️  Note: jq not found. JSON parsing may be limited."
    echo "   Consider installing jq for better output formatting."
fi

echo ""
echo "🎉 Workshop prerequisites verification complete!"
echo ""
echo "Next steps:"
echo "1. Navigate to the 'infra' directory"
echo "2. Create your terraform.auto.tfvars file with your unique prefix"
echo "3. Run 'terraform init' to initialize the configuration"
echo "4. Start with Part 1 of the workshop!"