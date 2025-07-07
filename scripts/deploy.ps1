# Load environment variables
$envFile = "terraform-credentials.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^export\s+([^=]+)=(.+)$") {
            $name = $matches[1]
            $value = $matches[2].Trim('"')
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
            Write-Host "Set $name" -ForegroundColor Green
        }
    }
    Write-Host "✅ Environment variables loaded" -ForegroundColor Green
} else {
    Write-Host "❌ terraform-credentials.env not found!" -ForegroundColor Red
    exit 1
}

# Initialize Terraform
if (!(Test-Path ".terraform")) {
    Write-Host "Initializing Terraform..." -ForegroundColor Yellow
    terraform init -backend-config=backend.hcl
}

# Validate configuration
Write-Host "Validating configuration..." -ForegroundColor Yellow
terraform validate

# Plan deployment
Write-Host "Creating deployment plan..." -ForegroundColor Yellow
terraform plan -out=tfplan

Write-Host ""
Write-Host "🎯 Deployment plan created!" -ForegroundColor Green
Write-Host ""
$confirmation = Read-Host "Proceed with deployment? This will create Azure resources (y/N)"

if ($confirmation -eq "y" -or $confirmation -eq "Y") {
    Write-Host ""
    Write-Host "🚀 Starting deployment..." -ForegroundColor Green
    Write-Host "This will take approximately 15-25 minutes..." -ForegroundColor Yellow
    
    terraform apply tfplan
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "🎉 DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
        Write-Host "========================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Configure kubectl access" -ForegroundColor White
        Write-Host "2. Test cluster connectivity" -ForegroundColor White
        Write-Host ""
        Write-Host "Run this command to get cluster access:" -ForegroundColor Yellow
        terraform output -raw aks_kubeconfig_command
    } else {
        Write-Host "❌ Deployment failed" -ForegroundColor Red
    }
} else {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
}
