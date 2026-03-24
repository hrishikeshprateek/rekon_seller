# CORS Configuration for Vercel Web Deployment

## Important: Backend CORS Setup

Since your web app will be deployed on Vercel, your backend API must allow CORS from the Vercel domain.

---

## 🔑 Key Points

1. **Web domain will be:** `https://your-project.vercel.app`
2. **Backend must allow:** Requests from the Vercel domain
3. **No proxy needed:** Direct API calls from web to backend
4. **CORS headers required:** Set on backend responses

---

## 🔧 Backend CORS Configuration

### For Node.js/Express

```javascript
const cors = require('cors');

// Option 1: Simple CORS for all origins (development only)
app.use(cors());

// Option 2: Specific origin (production recommended)
app.use(cors({
  origin: 'https://your-project.vercel.app',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'package_name'],
  credentials: true
}));

// Option 3: Multiple origins
const allowedOrigins = [
  'https://your-project.vercel.app',
  'http://localhost:8000', // local testing
  'https://your-custom-domain.com'
];

app.use(cors({
  origin: (origin, callback) => {
    if (allowedOrigins.includes(origin) || !origin) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'package_name'],
  credentials: true
}));

// Preflight request handler
app.options('*', cors());
```

### For Java/Spring Boot

```java
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
            .allowedOrigins("https://your-project.vercel.app")
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
            .allowedHeaders("Content-Type", "Authorization", "package_name")
            .allowCredentials(true)
            .maxAge(3600);
    }
}

// Or with multiple origins:
@Configuration
public class CorsConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        String[] allowedOrigins = {
            "https://your-project.vercel.app",
            "http://localhost:8000",
            "https://your-custom-domain.com"
        };
        
        registry.addMapping("/api/**")
            .allowedOrigins(allowedOrigins)
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(true)
            .maxAge(3600);
    }
}
```

### For Python/Flask

```python
from flask import Flask
from flask_cors import CORS

app = Flask(__name__)

# Option 1: All origins
CORS(app)

# Option 2: Specific origins
cors_config = {
    "origins": [
        "https://your-project.vercel.app",
        "http://localhost:8000",
        "https://your-custom-domain.com"
    ],
    "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    "allow_headers": ["Content-Type", "Authorization", "package_name"]
}
CORS(app, resources={r"/api/*": cors_config})
```

### For Python/Django

```python
# settings.py
INSTALLED_APPS = [
    # ...
    'corsheaders',
    # ...
]

MIDDLEWARE = [
    # ...
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    # ...
]

CORS_ALLOWED_ORIGINS = [
    "https://your-project.vercel.app",
    "http://localhost:8000",
    "https://your-custom-domain.com"
]

CORS_ALLOW_METHODS = [
    "DELETE",
    "GET",
    "OPTIONS",
    "PATCH",
    "POST",
    "PUT",
]

CORS_ALLOW_HEADERS = [
    "accept",
    "accept-encoding",
    "authorization",
    "content-type",
    "dnt",
    "origin",
    "user-agent",
    "x-csrftoken",
    "x-requested-with",
    "package_name",
]
```

### For PHP

```php
<?php
header('Access-Control-Allow-Origin: https://your-project.vercel.app');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, package_name');
header('Access-Control-Allow-Credentials: true');

// Handle preflight
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
?>
```

### For .NET/ASP.NET Core

```csharp
// Startup.cs or Program.cs
public void ConfigureServices(IServiceCollection services)
{
    services.AddCors(options =>
    {
        options.AddPolicy("AllowVercel", builder =>
        {
            builder.WithOrigins("https://your-project.vercel.app")
                   .AllowAnyMethod()
                   .AllowAnyHeader()
                   .AllowCredentials();
        });
    });
}

public void Configure(IApplicationBuilder app)
{
    app.UseCors("AllowVercel");
}
```

---

## 📝 Required CORS Headers

Your API responses should include:

```
Access-Control-Allow-Origin: https://your-project.vercel.app
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, package_name
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 86400
```

---

## 🧪 Testing CORS

### Test from your local machine:

```bash
# Replace with your actual domain
curl -i -X OPTIONS http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/getNdashboard \
  -H "Origin: https://your-project.vercel.app" \
  -H "Access-Control-Request-Method: GET"
```

### In browser console (F12):

```javascript
fetch('http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/getNdashboard', {
  method: 'GET',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN',
    'package_name': 'com.reckon.reckonbiz'
  }
})
.then(r => r.json())
.then(d => console.log('✓ CORS OK', d))
.catch(e => console.log('✗ CORS Error:', e.message));
```

---

## 🚨 Common CORS Errors

### Error: "No 'Access-Control-Allow-Origin' header"
**Solution:** Backend CORS not configured. Use code above for your framework.

### Error: "Credentials mode is 'include' but Access-Control-Allow-Credentials is missing"
**Solution:** Add `Access-Control-Allow-Credentials: true` in backend.

### Error: "Method not allowed"
**Solution:** Add `PUT`, `DELETE` to `allowedMethods`.

### Error: "Header not allowed"
**Solution:** Add `package_name` to `allowedHeaders`.

---

## 📋 Checklist Before Deploying Web

- [ ] Backend CORS configured for: `https://your-project.vercel.app`
- [ ] CORS headers include: `Content-Type`, `Authorization`, `package_name`
- [ ] Tested CORS with curl or browser console
- [ ] All API endpoints allow your Vercel domain
- [ ] Credentials are properly configured (`allowCredentials: true`)

---

## 🔄 Environment-Specific Configuration

### Development (Local Testing)
```
ALLOWED_ORIGINS: http://localhost:8000, http://localhost:3000
```

### Staging (Vercel Preview)
```
ALLOWED_ORIGINS: https://reckon-seller-2-0-staging.vercel.app
```

### Production (Vercel)
```
ALLOWED_ORIGINS: https://reckon-seller-2-0.vercel.app
```

### Custom Domain (Optional)
```
ALLOWED_ORIGINS: https://your-custom-domain.com
```

---

## 📞 Support

If you get CORS errors after deployment:
1. Check backend is running
2. Verify CORS headers are set
3. Test with curl/Postman first
4. Check browser Network tab (F12) for actual error
5. Ensure API URL is correct in your app

---

## ✅ Once CORS is Configured

Your web app will work perfectly:
- ✅ Direct API calls without proxy
- ✅ Real-time data updates
- ✅ Secure authentication
- ✅ Full feature parity with mobile

---

**Status: Ready for Web Deployment** 🚀

