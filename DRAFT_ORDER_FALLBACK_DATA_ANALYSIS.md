# Draft Order Page - Fallback Data Analysis

**Date**: March 20, 2026  
**Status**: ANALYSIS COMPLETE

## Navigation Flow

```
Home Page (home_screen.dart)
    ↓
[Draft Order Handler] (DraftOrderHandler widget)
    ↓
[DoAccountSelectorPage] (Account selection)
    ↓
[CartPage] (cart_page.dart)
```

## Fallback Data Available: ⚠️ **LIMITED**

When **draft_order_page** (CartPage) is opened via home page from account selector, the following fallback data exists:

### 1. ✅ **Account Information** (Passed from Selector)
```dart
CartPage(
  acCode: selectedAccount.code ?? selectedAccount.id,
  selectedAccount: selectedAccount,  // ← Account object passed
)
```

**Available Fallback Data from Account**:
- `selectedAccount.id` - Account ID
- `selectedAccount.code` - Account code
- `selectedAccount.name` - Account name (displayed in header)
- `selectedAccount.phone` - Account phone
- `selectedAccount.address` - Account address
- `selectedAccount.balance` - Account balance

### 2. ✅ **App/User Information** (From Auth Service)
```dart
final user = auth.currentUser;  // ← Always available
final mobile = user?.mobileNumber ?? '';
final licNo = user?.licenseNumber ?? '';
```

**Available Fallback Data**:
- Mobile number
- License number
- User ID
- Firm code (from stores)
- Device ID
- Device name

### 3. ❌ **Cart Data** - **NO FALLBACK**
```dart
Future<void> _loadCart() async {
  final response = await dio.post('/ListDraftOrder', ...);
  // No cached/fallback data - depends entirely on API response
  
  if (parsed['success'] == true && parsed['data'] != null) {
    final list = (parsed['data']['DraftOrder'] as List<dynamic>?) ?? [];
    // If API fails, _items remains empty []
    _items = list.map(...).toList();
  } else {
    _error = parsed['message']?.toString() ?? 'Failed to load cart';
    // _items stays empty!
  }
}
```

## What's Missing - No Fallback For:

### ❌ **Draft Order Items** (Cart Contents)
- **Issue**: If `ListDraftOrder` API fails, cart shows empty
- **No cache**: Previous cart data is not cached
- **No offline support**: No LocalStorage/SharedPreferences fallback

### ❌ **Cart Totals**
- No running total cached
- No previous total available if API fails

### ❌ **Order History**
- No fallback to recent orders
- Each session starts fresh

### ❌ **Product Information**
- No product cache
- Not loaded until accessing product detail page

## Current Behavior on API Failure

```
CartPage Opened
    ↓
_loadCart() called
    ↓
API Call to /ListDraftOrder
    ↓
    API Fails / Network Error
    ↓
_error = "Failed to load cart" (or actual error message)
_items = [] (empty list)
_isLoading = false
    ↓
UI Shows:
- Empty cart message
- Error message
- "Select Account" option to retry
```

## Code Flow - Cart Page LoadCart

```dart
@override
void initState() {
  _currentAcCode = widget.acCode;  // ✅ Available
  _selectedAccountName = widget.selectedAccount?.name;  // ✅ Available
  _loadCart();  // ❌ Depends on API
}

Future<void> _loadCart() async {
  // Get user data from auth
  final user = auth.currentUser;  // ✅ Available
  final mobile = user?.mobileNumber ?? '';  // ✅ Fallback to ''
  
  // API call - NO CACHING
  final response = await dio.post('/ListDraftOrder', ...);
  
  // Parse response
  final parsed = _parseJson(raw);
  
  // If success, parse items; otherwise error
  if (parsed['success'] == true) {
    _items = list.map(...).toList();  // ✅ Has fallback: []
  } else {
    _error = parsed['message'] ?? 'Failed to load cart';  // ❌ No fallback items
  }
}
```

## Recommendations for Improvement

### Priority 1 (Critical) - Add Cache Layer
```dart
class _CartPageState extends State<CartPage> {
  // Add cache
  List<DraftOrderItem>? _cachedItems;
  DateTime? _cacheTimestamp;
  
  Future<void> _loadCart() async {
    try {
      final response = await dio.post('/ListDraftOrder', ...);
      // If success, update cache
      _cachedItems = newItems;
      _cacheTimestamp = DateTime.now();
    } catch (e) {
      // Fallback to cached items if available
      if (_cachedItems != null) {
        _items = _cachedItems!;
        _error = 'Showing cached data - refresh to update';
      }
    }
  }
}
```

### Priority 2 (High) - Add LocalStorage Backup
```dart
// In cart_page.dart
Future<void> _saveCacheToStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = jsonEncode(_items.map((e) => e.toJson()).toList());
  await prefs.setString('cart_items_${_currentAcCode}', jsonString);
}

Future<void> _loadFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonString = prefs.getString('cart_items_${_currentAcCode}');
  if (jsonString != null) {
    final parsed = jsonDecode(jsonString) as List;
    return parsed.map((e) => DraftOrderItem.fromJson(e)).toList();
  }
  return [];
}
```

### Priority 3 (Medium) - Offline Indicator
```dart
// Show user when showing cached/offline data
if (_error == null && _cachedItems != null && !_isOnline) {
  showOfflineBanner('Showing cached data - connect to update');
}
```

## Current Fallback Status Summary

| Data Type | Fallback? | Source | Reliability |
|-----------|-----------|--------|------------|
| Account Info | ✅ Yes | Passed widget | High |
| User Info | ✅ Yes | Auth service | High |
| Cart Items | ❌ No | API only | Low (fails when offline) |
| Cart Totals | ❌ No | Calculated from API | Low |
| Product List | ❌ No | Not loaded | Low |
| Order History | ❌ No | Not cached | Low |

## Conclusion: ⚠️ **MINIMAL FALLBACK**

When draft_order_page opens from home:
- ✅ Account & user data are available
- ✅ Account name shows in header
- ❌ **Cart contents depend entirely on API call**
- ❌ **No offline support**
- ❌ **No data persistence between sessions**

**Risk**: If API fails or user is offline, cart appears empty even if items were previously added.

**Solution**: Implement caching layer with SharedPreferences backup before production.


