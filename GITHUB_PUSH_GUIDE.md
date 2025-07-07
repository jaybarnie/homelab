# 📚 GitHub Push Guide

This guide will help you push your AKS infrastructure project to GitHub safely and securely.

## 🔐 Security Checklist (CRITICAL!)

**⚠️ BEFORE PUSHING TO GITHUB - VERIFY THESE FILES ARE EXCLUDED:**

- ✅ `terraform-credentials.env` (contains secrets)
- ✅ `*.tfstate` files (contain sensitive state data)
- ✅ `*.tfstate.backup` files 
- ✅ `.terraform/` directory
- ✅ `terraform.tfplan` (may contain sensitive data)

Run this command to verify sensitive files are gitignored:
```powershell
git status --ignored
```

## � Organizing in Your Homelab Repository

Since you're pushing to an existing homelab repository, consider organizing your files:

### Option 1: Keep in Root (Current)
```powershell
# Files will be added to the root of your homelab repository
# This is fine if this is your main infrastructure project
```

### Option 2: Create Infrastructure Folder
```powershell
# Create a dedicated folder for infrastructure
mkdir infrastructure
mkdir infrastructure/aks
# Move all files to infrastructure/aks/
```

### Option 3: Create AKS-Specific Folder
```powershell
# Create an AKS-specific folder
mkdir aks-infrastructure
# Move all files to aks-infrastructure/
```

## �🚀 Step-by-Step GitHub Push Process

### Step 1: Initialize Git Repository

```powershell
# Navigate to your project directory
cd C:\Users\JarvisBarnie\hadandhed-aks-infrastructure

# Initialize git repository (if not already done)
git init

# Check current status
git status
```

### Step 2: Target Repository

**Target Repository**: `git@github.com:jaybarnie/homelab.git`

> **Note**: We'll be pushing this AKS infrastructure as a subfolder to your existing homelab repository.

### Step 3: Connect Local Repository to GitHub

```powershell
# Add GitHub remote to your homelab repository
git remote add origin git@github.com:jaybarnie/homelab.git

# Verify remote is added
git remote -v
```

### Step 4: Prepare Files for First Commit

```powershell
# Check what files will be added
git status

# Add all files (gitignore will exclude sensitive files)
git add .

# Verify no sensitive files are staged
git status

# Create initial commit
git commit -m "feat: add AKS infrastructure to homelab

- Production-ready AKS cluster configuration
- Modular Terraform structure
- Comprehensive monitoring and security
- PowerShell deployment scripts
- Complete documentation"
```

### Step 5: Push to GitHub

```powershell
# Push to GitHub (main branch)
git branch -M main
git push -u origin main
```

### Step 6: Verify Push Success

1. **Visit your GitHub repository**
2. **Verify files are present** and sensitive files are excluded
3. **Check README.md** displays correctly

## 🔧 Alternative: Using GitHub CLI

If you have GitHub CLI installed:

```powershell
# Install GitHub CLI (if not installed)
winget install GitHub.cli

# Login to GitHub
gh auth login

# Create repository and push to homelab
gh repo view jaybarnie/homelab

# Add remote and push
git remote add origin git@github.com:jaybarnie/homelab.git
git branch -M main
git push -u origin main
```

## 📋 Post-Push Checklist

After successfully pushing to GitHub:

- [ ] ✅ Verify README.md displays correctly
- [ ] ✅ Confirm no sensitive files in repository
- [ ] ✅ Check repository is private (if intended)
- [ ] ✅ Add repository description and topics
- [ ] ✅ Configure branch protection rules (optional)
- [ ] ✅ Set up GitHub Actions (if needed)

## 🛡️ Security Best Practices

### Repository Settings

1. **Make repository private** for infrastructure code
2. **Enable vulnerability alerts**
3. **Set up branch protection** for main branch
4. **Require PR reviews** for changes

### Ongoing Security

```powershell
# Before each push, always check status
git status

# Review changes before committing
git diff

# Use meaningful commit messages
git commit -m "feat: add monitoring configuration"
```

## 🔄 Future Updates Workflow

```powershell
# 1. Make changes to your infrastructure
# 2. Test changes locally
terraform plan

# 3. Stage and commit changes
git add .
git commit -m "update: improve node configuration"

# 4. Push to GitHub
git push origin main
```

## 🚨 Emergency: Remove Sensitive Data

If you accidentally commit sensitive data:

```powershell
# Remove file from last commit (if not pushed yet)
git reset HEAD~1
git add .gitignore
git commit -m "fix: remove sensitive files"

# If already pushed, contact GitHub support or use:
# git filter-branch or BFG Repo-Cleaner
```

## 📞 Support

If you encounter issues:

1. **Check Git status**: `git status`
2. **Verify remote**: `git remote -v`
3. **Check GitHub repository** online
4. **Review error messages** carefully

## Happy coding! 🚀

---

> **Remember**: Infrastructure code should always be treated as sensitive. Keep repositories private and review all commits carefully.
