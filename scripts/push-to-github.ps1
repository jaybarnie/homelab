# GitHub Push Script for AKS Infrastructure
# This script helps safely push your Terraform infrastructure to GitHub

param(
    [string]$GitHubRepo = "git@github.com:jaybarnie/homelab.git",
    [switch]$DryRun = $false
)

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param([string]$Message, [string]$Color)
    Write-Host "$Color$Message$Reset"
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-ColorOutput "=" * 60 $Blue
    Write-ColorOutput "  $Title" $Blue
    Write-ColorOutput "=" * 60 $Blue
    Write-Host ""
}

function Test-GitRepository {
    if (-not (Test-Path ".git")) {
        Write-ColorOutput "❌ Not a git repository. Initializing..." $Yellow
        git init
        Write-ColorOutput "✅ Git repository initialized" $Green
    }
}

function Test-SensitiveFiles {
    Write-Header "🔐 Security Check - Verifying Sensitive Files Are Excluded"
    
    $sensitiveFiles = @(
        "terraform-credentials.env",
        "*.tfstate",
        "*.tfstate.backup",
        ".terraform/",
        "terraform.tfplan"
    )
    
    $foundSensitiveFiles = @()
    
    foreach ($pattern in $sensitiveFiles) {
        $files = Get-ChildItem -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like $pattern }
        if ($files) {
            $foundSensitiveFiles += $files
        }
    }
    
    # Check if sensitive files are gitignored
    $gitStatus = git status --porcelain --ignored 2>$null
    $ignoredFiles = $gitStatus | Where-Object { $_ -match "^!!" }
    
    if ($foundSensitiveFiles) {
        Write-ColorOutput "⚠️  Found sensitive files:" $Yellow
        foreach ($file in $foundSensitiveFiles) {
            $relativePath = $file.FullName.Replace((Get-Location).Path, "").TrimStart('\')
            if ($ignoredFiles | Where-Object { $_ -match [regex]::Escape($relativePath) }) {
                Write-ColorOutput "  ✅ $relativePath (ignored)" $Green
            } else {
                Write-ColorOutput "  ❌ $relativePath (NOT ignored - DANGEROUS!)" $Red
                return $false
            }
        }
    } else {
        Write-ColorOutput "✅ No sensitive files found in working directory" $Green
    }
    
    return $true
}

function Get-GitHubUsername {
    if (-not $GitHubUsername) {
        $GitHubUsername = Read-Host "Enter your GitHub username"
    }
    
    if (-not $GitHubUsername) {
        Write-ColorOutput "❌ GitHub username is required!" $Red
        exit 1
    }
    
    return $GitHubUsername
}

function Test-GitHubCLI {
    try {
        $ghVersion = gh --version 2>$null
        if ($ghVersion) {
            Write-ColorOutput "✅ GitHub CLI is available" $Green
            return $true
        }
    } catch {
        Write-ColorOutput "⚠️  GitHub CLI not found. You'll need to create the repository manually." $Yellow
        return $false
    }
    return $false
}

function New-GitHubRepository {
    param([string]$Username, [string]$RepoName, [bool]$IsPrivate)
    
    $hasGitHubCLI = Test-GitHubCLI
    
    if ($hasGitHubCLI) {
        Write-ColorOutput "🚀 Creating GitHub repository using GitHub CLI..." $Blue
        
        $visibility = if ($IsPrivate) { "--private" } else { "--public" }
        $description = "Production-ready Azure Kubernetes Service (AKS) infrastructure using Terraform"
        
        if (-not $DryRun) {
            try {
                gh repo create $RepoName $visibility --description $description --confirm
                Write-ColorOutput "✅ Repository created successfully!" $Green
                return $true
            } catch {
                Write-ColorOutput "❌ Failed to create repository with GitHub CLI: $_" $Red
                return $false
            }
        } else {
            Write-ColorOutput "🔍 DRY RUN: Would create repository: $RepoName" $Yellow
            return $true
        }
    } else {
        Write-ColorOutput "📋 Please create the repository manually:" $Yellow
        Write-ColorOutput "  1. Go to: https://github.com/new" $Yellow
        Write-ColorOutput "  2. Repository name: $RepoName" $Yellow
        Write-ColorOutput "  3. Description: Production-ready Azure Kubernetes Service (AKS) infrastructure using Terraform" $Yellow
        Write-ColorOutput "  4. Set to: $(if ($IsPrivate) { 'Private' } else { 'Public' })" $Yellow
        Write-ColorOutput "  5. Don't initialize with README (we have existing code)" $Yellow
        Write-ColorOutput "  6. Click 'Create repository'" $Yellow
        
        Read-Host "Press Enter after creating the repository on GitHub"
        return $true
    }
}

function Set-GitRemote {
    param([string]$RepoUrl)
    
    # Check if remote already exists
    $existingRemote = git remote get-url origin 2>$null
    
    if ($existingRemote) {
        Write-ColorOutput "⚠️  Remote 'origin' already exists: $existingRemote" $Yellow
        $continue = Read-Host "Do you want to update it? (y/N)"
        if ($continue -eq 'y' -or $continue -eq 'Y') {
            if (-not $DryRun) {
                git remote set-url origin $RepoUrl
            }
            Write-ColorOutput "✅ Remote updated to: $RepoUrl" $Green
        }
    } else {
        if (-not $DryRun) {
            git remote add origin $RepoUrl
        }
        Write-ColorOutput "✅ Remote added: $RepoUrl" $Green
    }
}

function Invoke-GitCommitAndPush {
    Write-Header "📦 Staging, Committing, and Pushing Files"
    
    # Check git status
    $gitStatus = git status --porcelain
    if (-not $gitStatus) {
        Write-ColorOutput "ℹ️  No changes to commit" $Yellow
        return
    }
    
    # Show what will be committed
    Write-ColorOutput "📋 Files to be committed:" $Blue
    git status --short
    
    if (-not $DryRun) {
        # Stage all files
        git add .
        
        # Show staged files
        Write-ColorOutput "📋 Staged files:" $Blue
        git status --short
        
        # Commit with meaningful message
        $commitMessage = @"
feat: add AKS infrastructure to homelab

- Production-ready AKS cluster configuration
- Modular Terraform structure (networking, security, monitoring, storage)
- Comprehensive documentation and deployment guides
- PowerShell deployment scripts
- Security best practices implemented
- Cost-optimized configuration for production use

Environment: Production
Location: UK South
Contact: Jay@hadandhez.co.uk
"@
        
        git commit -m $commitMessage
        
        # Push to GitHub
        git branch -M main
        git push -u origin main
        
        Write-ColorOutput "🎉 Successfully pushed to GitHub!" $Green
    } else {
        Write-ColorOutput "🔍 DRY RUN: Would commit and push these files" $Yellow
    }
}

function Show-PostPushInstructions {
    param([string]$RepoUrl)
    
    Write-Header "🎉 Push Complete! Next Steps"
    
    Write-ColorOutput "🔗 Repository URL: $RepoUrl" $Green
    Write-ColorOutput "" $Reset
    Write-ColorOutput "📋 Recommended next steps:" $Blue
    Write-ColorOutput "  1. Visit your homelab repository and verify AKS files are present" $Reset
    Write-ColorOutput "  2. Check that sensitive files are NOT visible" $Reset
    Write-ColorOutput "  3. Update repository README to include AKS infrastructure section" $Reset
    Write-ColorOutput "  4. Consider organizing in an 'infrastructure/aks/' folder" $Reset
    Write-ColorOutput "  5. Configure branch protection rules" $Reset
    Write-ColorOutput "" $Reset
    Write-ColorOutput "🛡️  Security reminders:" $Yellow
    Write-ColorOutput "  - Keep repository private for infrastructure code" $Reset
    Write-ColorOutput "  - Enable vulnerability alerts" $Reset
    Write-ColorOutput "  - Review all commits before pushing" $Reset
    Write-ColorOutput "" $Reset
    Write-ColorOutput "📚 Documentation:" $Blue
    Write-ColorOutput "  - README.md: Project documentation" $Reset
    Write-ColorOutput "  - GITHUB_PUSH_GUIDE.md: Detailed push instructions" $Reset
    Write-ColorOutput "  - SETUP_SUMMARY.md: Project setup information" $Reset
}

# Main execution
Write-Header "🚀 AKS Infrastructure - GitHub Push Script"

try {
    # Step 1: Verify this is a git repository
    Test-GitRepository
    
    # Step 2: Security check for sensitive files
    Write-Header "🔐 Security Verification"
    if (-not (Test-SensitiveFiles)) {
        Write-ColorOutput "❌ SECURITY RISK: Sensitive files are not properly ignored!" $Red
        Write-ColorOutput "Please add these files to .gitignore and try again." $Red
        exit 1
    }
    
    # Step 3: Set git remote
    Write-Header "🔗 Configuring Git Remote"
    Set-GitRemote -RepoUrl $GitHubRepo
    
    # Step 4: Commit and push
    Invoke-GitCommitAndPush
    
    # Step 5: Show completion message
    Show-PostPushInstructions -RepoUrl $GitHubRepo
    
} catch {
    Write-ColorOutput "❌ Error occurred: $_" $Red
    Write-ColorOutput "Please check the error and try again." $Red
    exit 1
}

Write-ColorOutput "✅ Script completed successfully!" $Green
