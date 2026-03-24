# Deploy on Vercel Using Web Dashboard (UI)

## 🌐 Step-by-Step Guide for Web UI Deployment

### Prerequisites
- ✅ Vercel account (free at https://vercel.com)
- ✅ GitHub account with your project
- ✅ Code pushed to GitHub repository

---

## 📍 Step 1: Push Your Code to GitHub

Before using Vercel UI, your code must be on GitHub.

```bash
cd /Users/hrishikeshprateek/AndroidStudioProjects/reckon_seller_2_0

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Prepare for Vercel deployment"

# Add GitHub remote
git remote add origin https://github.com/YOUR_USERNAME/reckon_seller_2_0.git

# Push to GitHub
git branch -M main
git push -u origin main
```

Replace `YOUR_USERNAME` with your actual GitHub username.

---

## 🚀 Step 2: Deploy Using Vercel Dashboard

### 1️⃣ Go to Vercel Website
- Open https://vercel.com
- Click **"Sign In"** (or create account if new)
- Enter your GitHub credentials when prompted

### 2️⃣ Create New Project
- Click **"New Project"** button (top right area)
- Or go to: https://vercel.com/new

### 3️⃣ Select Your GitHub Repository
**Option A: If you see the repo in the list**
- Scroll down to find `reckon_seller_2_0`
- Click **"Import"**

**Option B: If you don't see it**
- Click **"Search"** box at top
- Type: `reckon_seller_2_0`
- Click the repo when it appears
- Click **"Import"**

### 4️⃣ Configure Project Settings

On the "Import Project" page, you'll see:

#### Project Name
- **Default:** `reckon_seller_2_0`
- ✅ Keep this or change it
- This becomes your Vercel URL

#### Environment Variables (Optional)
- Leave empty for now
- You can add later if needed

#### Build and Output Settings
Click **"Configure Build Settings"** and set:

| Field | Value |
|-------|-------|
| Framework | `Other` |
| Build Command | `flutter build web --release` |
| Output Directory | `build/web` |
| Install Command | `flutter pub get` |

**These are already in your `vercel.json`** ✅

### 5️⃣ Click "Deploy"
- Wait for build to complete (2-5 minutes)
- Watch the build progress in real-time
- ✅ When done, you'll see "Congratulations!"

---

## ✅ After Deployment

### Your Live App URL
The dashboard shows your live URL:
```
https://reckon-seller-2-0.vercel.app
```

### Share Your App
- Copy the URL
- Share with team
- App is live globally! 🎉

### Access Vercel Dashboard
Go to: https://vercel.com/dashboard
You'll see:
- Deployments
- Settings
- Analytics
- Domains

---

## 📊 Vercel Dashboard Overview

### Deployments Tab
Shows all your deployments with status:
- ✅ Ready (live)
- 🔄 Building
- ❌ Failed

Each deployment shows:
- Build time
- File size
- Commit message
- Deployment date

### Settings Tab
Configure:
- **Domains** - Add custom domain
- **Environment Variables** - API keys, secrets
- **Build & Development** - Build command, output
- **Git** - Connected GitHub repo

### Analytics Tab
View:
- Page views
- Core Web Vitals
- Response times
- Error rates

---

## 🔄 Automatic Deployments (After Initial Setup)

Once connected to GitHub:

1. **Make changes in your code**
2. **Commit and push to GitHub**
   ```bash
   git add .
   git commit -m "Your message"
   git push origin main
   ```
3. ✅ **Vercel automatically deploys!**

You'll see a new deployment in your Vercel dashboard.

---

## 🔧 Common Dashboard Tasks

### Set Custom Domain
1. Go to Vercel Dashboard
2. Click your project
3. Go to **Settings → Domains**
4. Click **"Add Domain"**
5. Enter your domain: `example.com`
6. Follow DNS instructions
7. Done! Your domain is live

### Rollback to Previous Deployment
1. Go to **Deployments** tab
2. Find the previous working deployment
3. Click the **"..."** menu
4. Click **"Promote to Production"**
5. Instant rollback! ⚡

### View Deployment Logs
1. Click on any deployment
2. Scroll down to see:
   - Build logs
   - Error messages
   - Build duration
   - Detailed output

### Add Environment Variables
1. Go to **Settings → Environment Variables**
2. Click **"Add New"**
3. Enter variable name and value
4. Select which environments (production/preview/development)
5. Click **"Save"**

---

## 🆘 If Deployment Fails

### Step 1: Check Build Logs
- Vercel Dashboard → Click failed deployment
- Scroll to see error message
- Look for the actual error

### Step 2: Common Issues

**Error: "Flutter not found"**
- Vercel needs Flutter SDK installed
- This usually works automatically
- Try re-deploying: Click deployment → Menu → "Redeploy"

**Error: "build/web directory not found"**
- Build command didn't complete
- Check `vercel.json` is in project root
- Verify `flutter build web --release` works locally

**Error: "Blank white screen"**
- App deployed but has JavaScript errors
- Open your live URL
- Press F12 to open DevTools
- Check Console tab for errors

### Step 3: Redeploy from Dashboard
1. Go to Deployments
2. Click the **"..."** menu on your deployment
3. Click **"Redeploy"**
4. Wait for build to complete

---

## 📱 Test Your Live Deployment

### In Browser
1. Open your Vercel URL: `https://reckon-seller-2-0.vercel.app`
2. Open DevTools (F12)
3. Check Console tab (no red errors)
4. Check Network tab (all requests successful)
5. Test features:
   - Login
   - Browse products
   - Add to cart
   - API calls

### Verify API Calls
In browser console (F12 → Console):
```javascript
fetch('https://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/GetSalesmanFlags', {
  headers: {
    'package_name': 'com.reckon.reckonbiz'
  }
})
.then(r => r.json())
.then(d => console.log('✓ API works:', d))
.catch(e => console.log('✗ API failed:', e))
```

---

## 🎯 Complete Checklist

### Before Deployment
- [ ] Code pushed to GitHub
- [ ] `vercel.json` in project root
- [ ] `flutter build web --release` works locally

### During Deployment
- [ ] Vercel account created
- [ ] GitHub repo imported
- [ ] Build settings configured
- [ ] Deploy button clicked
- [ ] Waiting for build to complete

### After Deployment
- [ ] App loads without blank screen
- [ ] Console has no errors (F12)
- [ ] API calls work
- [ ] Features tested
- [ ] URL shared with team

---

## 📞 Important: Backend CORS

**Tell your backend team:**

Your web app is now at:
```
https://reckon-seller-2-0.vercel.app
```

They need to add CORS headers for this domain:
```
Access-Control-Allow-Origin: https://reckon-seller-2-0.vercel.app
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, package_name
```

See **CORS_SETUP_GUIDE.md** for backend code examples.

---

## 🔗 Useful Dashboard Links

| Task | Link |
|------|------|
| View Dashboard | https://vercel.com/dashboard |
| New Project | https://vercel.com/new |
| Account Settings | https://vercel.com/account |
| Documentation | https://vercel.com/docs |

---

## 📊 What You Can Do in Dashboard

### Deployments
- ✅ View all versions
- ✅ Rollback to previous
- ✅ Redeploy anytime
- ✅ View build logs
- ✅ Share preview links

### Settings
- ✅ Custom domain
- ✅ Environment variables
- ✅ Git integration
- ✅ Build settings
- ✅ Redirect rules

### Analytics
- ✅ Page views
- ✅ Performance metrics
- ✅ Error tracking
- ✅ Traffic analysis

### Team (Paid Plans)
- ✅ Invite team members
- ✅ Manage permissions
- ✅ Shared projects
- ✅ SSO integration

---

## 💡 Pro Tips

### Tip 1: Preview URLs
Each deployment gets a preview URL:
```
https://reckon-seller-2-0-abc123.vercel.app
```
Share this before promoting to production.

### Tip 2: Custom Domain
Add your custom domain in Settings → Domains:
```
https://app.yourcompany.com
```

### Tip 3: Environment Variables
Set API URLs per environment:
- Production: Your live API
- Preview: Staging API
- Development: Local API

### Tip 4: Automatic Deployments
GitHub integration means:
- Every push = new deployment
- Automatic testing
- Instant rollback if needed

### Tip 5: Monitor with Analytics
Track user experience:
- Page load times
- Core Web Vitals
- Error rates
- Traffic patterns

---

## 🎉 Success Indicators

When deployment is complete:

✅ **Green checkmark** on deployment in dashboard
✅ **"Ready"** status showing
✅ **URL is accessible** (no 404 errors)
✅ **App loads** (no blank screen)
✅ **Console clean** (F12 → no red errors)
✅ **API calls work** (network requests successful)
✅ **Features functional** (login, browse, add to cart)

---

## 🚀 Next Steps

1. **Go to:** https://vercel.com
2. **Click:** "New Project"
3. **Select:** Your GitHub repo
4. **Configure:** Build settings (usually auto-detected)
5. **Click:** "Deploy"
6. **Wait:** 2-5 minutes for build
7. **Share:** Your live URL! 🎉

---

## 📚 More Information

See these guides for additional help:
- **VERCEL_QUICK_START.md** - CLI method (alternative)
- **VERCEL_DEPLOYMENT.md** - Complete reference
- **CORS_SETUP_GUIDE.md** - Backend configuration
- **WEB_DEPLOYMENT_GUIDE.md** - All deployment methods

---

**Status: Ready to Deploy via Vercel UI!** ✅

**Go to:** https://vercel.com/new and click "Import Project" 🚀

