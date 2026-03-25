# Web API Proxy Configuration for Vercel

## Overview
The web application has been configured to use Vercel's built-in rewrite/proxy feature to handle CORS issues when calling the backend API. This eliminates the need for modifying backend CORS settings.

## Changes Made

### 1. **vercel.json** - Proxy Rewrite Configuration
```json
{
  "rewrites": [
    {
      "source": "/reckon-biz/api/reckonpwsorder/:path*",
      "destination": "http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/:path*"
    }
  ]
}
```

This configuration tells Vercel to:
- Intercept requests to `/reckon-biz/api/reckonpwsorder/*`
- Proxy them to the actual backend at `http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/*`
- Handle CORS headers automatically

### 2. **lib/auth_service.dart** - Updated `apiBaseUrl` and `getDioClient()`

**Before:**
```dart
String get apiBaseUrl {
  if (kIsWeb) {
    return proxyUrl; // localhost:3000
  }
  return baseUrl; // direct backend
}
```

**After:**
```dart
String get apiBaseUrl {
  if (kIsWeb) {
    return '/reckon-biz/api/reckonpwsorder'; // Vercel proxy
  }
  return baseUrl; // direct backend
}
```

Similar changes to `getDioClient()` method to use the proxy for web.

### 3. **lib/dashboard_service.dart** - Updated Base URL Selection
```dart
DashboardService(this.authService) : _dio = Dio() {
  final apiUrl = kIsWeb ? '/reckon-biz/api/reckonpwsorder' : baseUrl;
  _dio.options.baseUrl = apiUrl;
  // ...
}
```

### 4. **lib/services/salesman_flags_service.dart** - Updated Base URL Selection
```dart
SalesmanFlagsService() {
  final apiUrl = kIsWeb ? '/reckon-biz/api/reckonpwsorder' : baseUrl;
  _dio.options.baseUrl = apiUrl;
  // ...
}
```

### 5. **lib/pages/receipt_details_page.dart** - Replaced Manual Dio with getDioClient()
**Before:**
```dart
final dio = Dio(); // manual instantiation
final response = await dio.post(
  'http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/GetReceiptDetail',
  // ...
);
```

**After:**
```dart
final dio = auth.getDioClient(); // uses proxy for web
final response = await dio.post(
  '/GetReceiptDetail',
  // ...
);
```

### 6. **lib/pages/location_picker_sheet.dart** - Replaced Manual Dio with getDioClient()
**Before:**
```dart
final dio = Dio(BaseOptions(
  baseUrl: 'http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder',
  // ...
));
```

**After:**
```dart
final dio = auth.getDioClient(); // uses proxy for web
```

## How It Works

### Request Flow (Web)
```
Web Browser
    ↓
https://your-vercel-app.vercel.app/reckon-biz/api/reckonpwsorder/ValidateLicense
    ↓
Vercel Proxy (rewrites to)
    ↓
http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/ValidateLicense
    ↓
Backend API
```

### Request Flow (Mobile)
```
Mobile App
    ↓
http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder/ValidateLicense
    ↓
Backend API (Direct Call)
```

## Testing

1. **Redeploy to Vercel:**
   ```bash
   git add .
   git commit -m "Configure Vercel proxy for web CORS handling"
   git push
   ```

2. **Verify in Browser Console:**
   - Open Developer Tools → Network tab
   - Check that requests to `/reckon-biz/api/reckonpwsorder/*` succeed
   - No CORS errors should appear

3. **Test Key Flows:**
   - ✅ Login with license and password
   - ✅ MPIN validation
   - ✅ Dashboard loading
   - ✅ Salesman flags loading
   - ✅ Order entry and product selection
   - ✅ Cart operations
   - ✅ Receipt details

## Benefits

✅ **No CORS Errors** - Vercel handles CORS headers automatically  
✅ **No Backend Changes** - Backend CORS settings remain unchanged  
✅ **Consistent Codebase** - Single code path uses platform detection  
✅ **Mobile Unaffected** - Mobile still uses direct API calls  
✅ **Production Ready** - Vercel proxy is production-grade  

## Troubleshooting

If APIs still not loading after redeployment:

1. **Clear browser cache** - Ctrl+Shift+Del (Windows) or Cmd+Shift+Del (Mac)
2. **Hard refresh** - Ctrl+F5 (Windows) or Cmd+Shift+R (Mac)
3. **Check Network tab** - Verify request URL shows `/reckon-biz/api/reckonpwsorder/*`
4. **Check Vercel logs** - Visit https://vercel.com and check deployment logs
5. **Verify backend URL** - Ensure `http://mobileappsandbox.reckonsales.com:8080` is accessible

## Additional Notes

- The proxy configuration is zero-cost and built into Vercel's platform
- Response times should be minimal as Vercel is likely deployed close to your backend
- All authentication headers are properly forwarded through the proxy
- The solution is compatible with all API endpoints since it rewrites at the URL path level

