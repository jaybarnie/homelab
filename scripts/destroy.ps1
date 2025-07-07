# =============================================================================
# scripts/destroy.ps1 - Terraform Destroy Script
# =============================================================================

Write-Host "🔥 TERRAFORM DESTROY SCRIPT" -ForegroundColor Red
Write-Host "===========================" -ForegroundColor Red
Write-Host ""

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

Write-Host ""
Write-Host "⚠️  WARNING: This will DESTROY ALL Azure resources!" -ForegroundColor Yellow
Write-Host "⚠️  This action is IRREVERSIBLE!" -ForegroundColor Yellow
Write-Host ""

# Show what will be destroyed
Write-Host "Creating destruction plan..." -ForegroundColor Yellow
terraform plan -destroy

Write-Host ""
Write-Host "💥 Resources to be DESTROYED shown above!" -ForegroundColor Red
Write-Host ""

$confirmation = Read-Host "Are you ABSOLUTELY SURE you want to destroy everything? Type 'DESTROY' to confirm"

if ($confirmation -eq "DESTROY") {
    Write-Host ""
    Write-Host "💥 Starting destruction..." -ForegroundColor Red
    Write-Host "This may take several minutes..." -ForegroundColor Yellow
    
    terraform destroy -auto-approve
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ DESTRUCTION COMPLETE!" -ForegroundColor Green
        Write-Host "All Azure resources have been destroyed." -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "❌ Destruction failed or incomplete" -ForegroundColor Red
        Write-Host "Some resources may still exist. Check Azure Portal." -ForegroundColor Yellow
    }
} else {
    Write-Host "Destruction cancelled. Your resources are safe." -ForegroundColor Green
}