#!/usr/bin/env pwsh

Write-Host "🔍 Verifying workshop prerequisites..." -ForegroundColor Cyan

$hasErrors = $false

# Check Terraform installation
try {
    $terraformVersion = terraform version -json | ConvertFrom-Json
    Write-Host "✅ Terraform found: $($terraformVersion.terraform_version)" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform not found. Please install Terraform CLI." -ForegroundColor Red
    Write-Host "   Installation guide: https://developer.hashicorp.com/terraform/install" -ForegroundColor Yellow
    Write-Host "   Windows (chocolatey): choco install terraform" -ForegroundColor Yellow
    Write-Host "   Windows (manual): Download from the link above" -ForegroundColor Yellow
    $hasErrors = $true
}

# Check gcloud installation
try {
    $gcloudVersion = gcloud version --format="value(Google Cloud SDK)" 2>$null | Select-Object -First 1
    if ($gcloudVersion) {
        Write-Host "✅ Google Cloud SDK found: $gcloudVersion" -ForegroundColor Green
    } else {
        # Fallback to parsing full version output
        $gcloudFull = gcloud --version 2>$null | Select-Object -First 1
        if ($gcloudFull -match "Google Cloud SDK (\d+\.\d+\.\d+)") {
            Write-Host "✅ Google Cloud SDK found: $($matches[1])" -ForegroundColor Green
        } else {
            Write-Host "✅ Google Cloud SDK found (version detection failed)" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "❌ gcloud not found. Please install Google Cloud SDK." -ForegroundColor Red
    Write-Host "   Installation guide: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    Write-Host "   Windows (chocolatey): choco install gcloudsdk" -ForegroundColor Yellow
    Write-Host "   Windows (manual): Download from the link above" -ForegroundColor Yellow
    $hasErrors = $true
}

# Check gcloud authentication
try {
    $activeAccount = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
    if ($activeAccount) {
        Write-Host "✅ Authenticated as: $activeAccount" -ForegroundColor Green
    } else {
        Write-Host "❌ Not authenticated with gcloud. Please run 'gcloud auth login'" -ForegroundColor Red
        $hasErrors = $true
    }
} catch {
    Write-Host "❌ Error checking gcloud authentication. Please run 'gcloud auth login'" -ForegroundColor Red
    $hasErrors = $true
}

# Check application default credentials
try {
    $adcTest = gcloud auth application-default print-access-token 2>$null
    if ($adcTest) {
        Write-Host "✅ Application Default Credentials configured" -ForegroundColor Green
    } else {
        throw "No ADC configured"
    }
} catch {
    Write-Host "⚠️  Application Default Credentials not configured. Please run:" -ForegroundColor Yellow
    Write-Host "   gcloud auth application-default login" -ForegroundColor Yellow
    Write-Host "   This is required for Terraform to authenticate with Google Cloud." -ForegroundColor Yellow
}

# Check project configuration
try {
    $projectId = gcloud config get-value project 2>$null
    if ($projectId -and $projectId -ne "(unset)") {
        Write-Host "✅ Project configured: $projectId" -ForegroundColor Green
        
        # Verify project access
        try {
            $projectDesc = gcloud projects describe $projectId 2>$null
            if ($projectDesc) {
                Write-Host "✅ Project access verified" -ForegroundColor Green
            } else {
                throw "Cannot describe project"
            }
        } catch {
            Write-Host "❌ Cannot access project: $projectId" -ForegroundColor Red
            Write-Host "   Please ensure you have the necessary permissions or set the correct project." -ForegroundColor Yellow
            $hasErrors = $true
        }
    } else {
        Write-Host "⚠️  No default project configured. You may need to run:" -ForegroundColor Yellow
        Write-Host "   gcloud config set project YOUR_PROJECT_ID" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Error checking project configuration" -ForegroundColor Yellow
}

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
    Write-Host "✅ PowerShell version: $($psVersion.ToString())" -ForegroundColor Green
} else {
    Write-Host "⚠️  PowerShell version $($psVersion.ToString()) detected. PowerShell 5.0+ recommended." -ForegroundColor Yellow
}

# Check if running in Windows and provide Windows-specific tips
if ($IsWindows -or $env:OS -eq "Windows_NT") {
    Write-Host "💡 Windows detected. Workshop commands are provided for both PowerShell and Command Prompt." -ForegroundColor Blue
}

Write-Host ""
if ($hasErrors) {
    Write-Host "⚠️  Some prerequisites are missing. Please install them before continuing." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "🎉 Workshop prerequisites verification complete!" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Navigate to the 'infra' directory: cd infra" -ForegroundColor White
Write-Host "2. Create your terraform.auto.tfvars file with your unique prefix" -ForegroundColor White
Write-Host "3. Run 'terraform init' to initialize the configuration" -ForegroundColor White
Write-Host "4. Start with Part 1 of the workshop!" -ForegroundColor White