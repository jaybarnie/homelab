# 🚀 Quick Push Commands

Ready to push your AKS infrastructure to your homelab repository? Here are the commands:

## Option 1: Use the Automated Script

```powershell
# Run from the project root directory
.\scripts\quick-push.ps1
```

## Option 2: Manual Commands

```powershell
# Navigate to your project directory
cd C:\Users\JarvisBarnie\hadandhed-aks-infrastructure

# Initialize git (if not already done)
git init

# Add the homelab remote
git remote add origin git@github.com:jaybarnie/homelab.git

# Check what files will be committed (verify no sensitive files)
git status

# Add all files
git add .

# Commit with a meaningful message
git commit -m "feat: add AKS infrastructure to homelab

- Production-ready AKS cluster configuration
- Modular Terraform structure
- Comprehensive monitoring and security
- PowerShell deployment scripts
- Complete documentation"

# Push to homelab repository
git branch -M main
git push -u origin main
```

## ⚠️ Before You Push - Security Check

Run this command to verify sensitive files are excluded:

```powershell
git status --ignored
```

Make sure these files are NOT being committed:
- `terraform-credentials.env`
- `*.tfstate` files
- `*.tfstate.backup` files
- `.terraform/` directory

## 🎯 Ready? Run This Single Command:

```powershell
.\scripts\quick-push.ps1
```

---

**Target Repository**: `git@github.com:jaybarnie/homelab.git`
