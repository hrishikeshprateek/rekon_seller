# Quick Start: Deploy Reckon BIZ360 Web

## 🚀 Fastest Way to Deploy (Firebase - Recommended)

### 1️⃣ Install Firebase CLI
```bash
# macOS/Linux
brew install firebase-cli

# Windows
npm install -g firebase-tools
```

### 2️⃣ Login to Firebase
```bash
firebase login
```

### 3️⃣ Use the Deploy Script
```bash
chmod +x deploy.sh
./deploy.sh firebase
```

**That's it!** Your app will be deployed and the URL will be printed.

---

## 🔧 Manual Steps (If Preferred)

```bash
# 1. Navigate to project
cd /Users/hrishikeshprateek/AndroidStudioProjects/reckon_seller_2_0

# 2. Build for web
flutter clean
flutter pub get
flutter build web --release

# 3. Deploy to Firebase
firebase deploy --only hosting
```

---

## 📝 Configuration Steps

### Step 1: Initialize Firebase (First Time Only)
```bash
firebase init hosting
```
When prompted:
- ✅ Select your Firebase project
- ✅ Public directory: `build/web`
- ❌ Rewrite URLs: No
- ❌ Overwrite index.html: No

### Step 2: Update `.firebaserc`
Copy template and update with your project ID:
```bash
cp .firebaserc.example .firebaserc
```

Edit `.firebaserc` and replace:
- `"default": "reckon-seller-2-0"` with your Firebase project ID

---

## 🌐 Other Deployment Options

### Vercel (Fast CDN)
```bash
./deploy.sh vercel
```

### Local Testing
```bash
./deploy.sh local
# Opens http://localhost:8000
```

---

## ✅ Verify Deployment

After deployment:
1. Open your Firebase URL (e.g., `https://your-project.web.app`)
2. Open DevTools (F12)
3. Check Console for any errors
4. Test API calls to verify backend connectivity
5. Test all features (login, browsing, etc.)

---

## 📊 Deployment Methods Comparison

| Method | Cost | Speed | Ease | Best For |
|--------|------|-------|------|----------|
| Firebase | Free | ⚡⚡⚡ | ⭐⭐⭐⭐⭐ | **Recommended** |
| Vercel | Free | ⚡⚡⚡ | ⭐⭐⭐⭐ | Performance |
| Netlify | Free | ⚡⭐⭐ | ⭐⭐⭐⭐ | GitHub Integration |
| Self-Hosted | Variable | Variable | ⭐⭐ | Full Control |

---

## 🔑 Important Notes

### API Configuration
Your app uses `mobileappsandbox.reckonsales.com:8080` as the API base.

**For Production:** Update to your production API URL in:
- `lib/auth_service.dart`
- `.env` files (if using)

### Environment Setup
```dart
// In your services, update:
const String apiBaseUrl = 'https://your-production-api.com';
```

### CORS Configuration
Ensure your backend allows requests from your Firebase domain:
```
Access-Control-Allow-Origin: https://your-project.web.app
```

---

## 🆘 Troubleshooting

### "Firebase CLI not found"
```bash
npm install -g firebase-tools
firebase login
```

### "Blank white screen after deployment"
1. Clear cache: Ctrl+Shift+Delete (Chrome DevTools)
2. Check console for errors (F12)
3. Verify base href in index.html

### "API calls returning 403/CORS errors"
Update your backend to allow web domain:
```
Allow-Origin: https://your-project.web.app
```

### "Large bundle size warning"
```bash
flutter build web --release --minify
```

---

## 📚 Full Documentation

See `WEB_DEPLOYMENT_GUIDE.md` for comprehensive deployment information.

---

## 🎯 Next Steps

1. ✅ Install Firebase CLI
2. ✅ Run `firebase login`
3. ✅ Run `./deploy.sh firebase`
4. ✅ Share the generated URL
5. ✅ Test all features

**Questions?** Check WEB_DEPLOYMENT_GUIDE.md or run:
```bash
./deploy.sh
```

---

**Status:** Ready to Deploy 🚀
**Last Updated:** March 24, 2026

