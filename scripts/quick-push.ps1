#!/usr/bin/env pwsh

# Quick GitHub Push Script
# Simple one-command push to homelab repository

Write-Host "🚀 Quick GitHub Push for AKS Infrastructure to Homelab" -ForegroundColor Blue
Write-Host "======================================================" -ForegroundColor Blue

# Target repository
$repoUrl = "git@github.com:jaybarnie/homelab.git"
Write-Host "Target: $repoUrl" -ForegroundColor Cyan

# Run the full push script
$scriptPath = Join-Path $PSScriptRoot "push-to-github.ps1"

if (Test-Path $scriptPath) {
    Write-Host "🔄 Running push script..." -ForegroundColor Green
    & $scriptPath -GitHubRepo $repoUrl
} else {
    Write-Host "❌ Push script not found at: $scriptPath" -ForegroundColor Red
    Write-Host "Please ensure you're running this from the scripts directory." -ForegroundColor Yellow
}
