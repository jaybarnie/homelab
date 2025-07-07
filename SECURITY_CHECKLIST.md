# 📋 Pre-Push Security Checklist

**⚠️ CRITICAL: Complete this checklist before pushing to GitHub!**

## 🔐 Security Verification

### Files to NEVER commit:
- [ ] `terraform-credentials.env` - Contains Azure credentials
- [ ] `*.tfstate` - Contains infrastructure state (may include secrets)
- [ ] `*.tfstate.backup` - Backup state files
- [ ] `.terraform/` - Terraform working directory
- [ ] `terraform.tfplan` - May contain sensitive plan data
- [ ] Any files with passwords, keys, or certificates

### Verification Commands:
```powershell
# Check git status (should not show sensitive files)
git status

# Check what would be committed
git status --short

# Check ignored files
git status --ignored

# Verify .gitignore is working
git check-ignore terraform-credentials.env
# Should output: terraform-credentials.env
```

## 📁 Repository Setup

### Repository Settings:
- [ ] Repository name: `hadandhed-aks-infrastructure`
- [ ] Description: "Production-ready Azure Kubernetes Service (AKS) infrastructure using Terraform"
- [ ] Visibility: **Private** (recommended for infrastructure)
- [ ] Initialize with README: **No** (we have existing files)

### Required Files Present:
- [ ] `README.md` - Project documentation
- [ ] `.gitignore` - Excludes sensitive files
- [ ] `GITHUB_PUSH_GUIDE.md` - Push instructions
- [ ] `SECURITY_CHECKLIST.md` - This file
- [ ] All Terraform files (`*.tf`, `*.tfvars`)
- [ ] Module files in `modules/` directory
- [ ] Scripts in `scripts/` directory

## 🚀 Push Process

### Before First Push:
- [ ] Complete security verification above
- [ ] Review all files to be committed
- [ ] Ensure no hardcoded secrets in any files
- [ ] Test .gitignore is working properly

### Push Commands:
```powershell
# Option 1: Use automated script
.\scripts\push-to-github.ps1 -GitHubUsername "your-username"

# Option 2: Manual process
git init
git add .
git commit -m "Initial commit: AKS infrastructure"
git branch -M main
git remote add origin https://github.com/your-username/hadandhed-aks-infrastructure.git
git push -u origin main
```

## ✅ Post-Push Verification

### After Successful Push:
- [ ] Visit GitHub repository
- [ ] Verify README.md displays correctly
- [ ] Confirm sensitive files are NOT visible
- [ ] Check repository is private (if intended)
- [ ] Review commit history looks correct

### GitHub Repository Configuration:
- [ ] Add repository description
- [ ] Add topics: `azure`, `kubernetes`, `terraform`, `infrastructure`
- [ ] Enable vulnerability alerts
- [ ] Configure branch protection (optional)
- [ ] Set up GitHub Actions (optional)

## 🛡️ Ongoing Security

### For Future Commits:
- [ ] Always run `git status` before committing
- [ ] Review changes with `git diff`
- [ ] Use meaningful commit messages
- [ ] Test changes locally before pushing

### Emergency Procedures:
If you accidentally commit sensitive data:
1. **DO NOT** push to GitHub yet
2. Reset the commit: `git reset HEAD~1`
3. Fix the issue and commit again
4. If already pushed, contact GitHub support immediately

## 📞 Support

If you encounter issues:
- Check this checklist again
- Review error messages carefully
- Consult `GITHUB_PUSH_GUIDE.md` for detailed instructions
- Contact: Jay@hadandhez.co.uk

---

**🎯 Remember: Security first! It's better to be safe than sorry with infrastructure code.**
