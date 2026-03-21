# API Response Logging - Account Selection ✅

**Date**: March 20, 2026  
**Status**: LOGGING ADDED

## What Was Added

Added comprehensive logging to track and print API responses from the account selector page.

## Logging Locations

### 1. **DoAccountSelectorPage - API Response Logging**

**Location**: `lib/pages/do_account_selector_page.dart` in `_loadAccounts()` method

**What's logged**:
```dart
debugPrint('===== GetDoAccount API RESPONSE =====');
debugPrint('RAW RESPONSE: ${response.data}');
debugPrint('=====================================');

debugPrint('[GetDoAccount] PARSED RESPONSE: $parsed');
debugPrint('[GetDoAccount] Total Accounts Found: ${items.length}');
for (int i = 0; i < items.length; i++) {
  final item = items[i];
  debugPrint('[GetDoAccount] Account $i: ${item['Name']} (${item['Code']})');
}
```

**Output Example**:
```
===== GetDoAccount API RESPONSE =====
RAW RESPONSE: {success: true, message: Success, rs: 1, data: {Account: [{Code: 001463, Name: 314 FIELD HOSPITAL, ...}, {Code: 004315, Name: A-ONE PHARMACY, ...}]}, baseUrl: null, dbName: null}
=====================================
[GetDoAccount] PARSED RESPONSE: {success: true, message: Success, rs: 1, data: {Account: [...]}, baseUrl: null, dbName: null}
[GetDoAccount] Total Accounts Found: 2
[GetDoAccount] Account 0: 314 FIELD HOSPITAL (001463)
[GetDoAccount] Account 1: A-ONE PHARMACY (004315)
```

### 2. **DraftOrderHandler - Selection Flow Logging**

**Location**: `lib/home_screen.dart` in `_handleAccountSelection()` method

**What's logged**:
```dart
debugPrint('[DraftOrderHandler] ===== ACCOUNT SELECTION STARTED =====');
debugPrint('[DraftOrderHandler] Opening DoAccountSelectorPage');
// ... after selection ...
debugPrint('[DraftOrderHandler] Selected Account Details:');
debugPrint('[DraftOrderHandler]   - Name: ${selectedAccount.name}');
debugPrint('[DraftOrderHandler]   - ID: ${selectedAccount.id}');
debugPrint('[DraftOrderHandler]   - Code: ${selectedAccount.code}');
debugPrint('[DraftOrderHandler]   - Phone: ${selectedAccount.phone}');
debugPrint('[DraftOrderHandler]   - Address: ${selectedAccount.address}');
debugPrint('[DraftOrderHandler]   - Type: ${selectedAccount.type}');
debugPrint('[DraftOrderHandler] Navigating to CartPage with acCode: ...');
debugPrint('[DraftOrderHandler] ===== ACCOUNT SELECTION COMPLETED =====');
```

**Output Example**:
```
[DraftOrderHandler] ===== ACCOUNT SELECTION STARTED =====
[DraftOrderHandler] Opening DoAccountSelectorPage
[DraftOrderHandler] Selected Account Details:
[DraftOrderHandler]   - Name: 314 FIELD HOSPITAL
[DraftOrderHandler]   - ID: 001463
[DraftOrderHandler]   - Code: 001463
[DraftOrderHandler]   - Phone: 7261993380
[DraftOrderHandler]   - Address: CLEMENT TOWN, DEHRA DUN 248001
[DraftOrderHandler]   - Type: Party
[DraftOrderHandler] Navigating to CartPage with acCode: 001463
[DraftOrderHandler] Building CartPage for account: 001463
[DraftOrderHandler] ===== ACCOUNT SELECTION COMPLETED =====
```

## How to View Logs

When running the app:

1. **From Flutter Console/Logcat**: 
   - Open your Flutter console
   - Search for `GetDoAccount` or `DraftOrderHandler`
   - You'll see the full API response and account details

2. **From Android Studio Logcat**:
   - Run → Edit Configurations → Logcat
   - Filter for `GetDoAccount` or `DraftOrderHandler`

3. **Real-time**:
   - Run `flutter run` in terminal
   - When you open "Draft Order", you'll see all logs in real-time

## Log Flow

```
User opens "Draft Order" from Home
    ↓
[DraftOrderHandler] ===== ACCOUNT SELECTION STARTED =====
[DraftOrderHandler] Opening DoAccountSelectorPage
    ↓
DoAccountSelectorPage API call to /GetDoAccount
    ↓
===== GetDoAccount API RESPONSE =====
[Raw response printed]
[GetDoAccount] PARSED RESPONSE: ...
[GetDoAccount] Total Accounts Found: 2
[GetDoAccount] Account 0: 314 FIELD HOSPITAL (001463)
[GetDoAccount] Account 1: A-ONE PHARMACY (004315)
    ↓
User selects account
    ↓
[DraftOrderHandler] Selected Account Details:
[DraftOrderHandler]   - Name: 314 FIELD HOSPITAL
[DraftOrderHandler]   - ID: 001463
[etc...]
    ↓
[DraftOrderHandler] Navigating to CartPage with acCode: 001463
[DraftOrderHandler] ===== ACCOUNT SELECTION COMPLETED =====
    ↓
CartPage opens
```

## Files Modified

1. **lib/pages/do_account_selector_page.dart**
   - Added logging after API response
   - Shows raw and parsed response
   - Lists all accounts found

2. **lib/home_screen.dart**
   - Enhanced DraftOrderHandler logging
   - Shows selected account details
   - Tracks navigation flow

## What You Can Debug With These Logs

✅ **Check if API is returning data**
- See raw API response
- Verify success status

✅ **See which accounts are returned**
- Account count
- Account names and codes
- All account details

✅ **Track user selection**
- Which account was selected
- All account properties
- Navigation flow

✅ **Verify no cached data issue**
- Fresh API call each time
- Check response for the same accounts

## Status: READY TO LOG ✅

When you open "Draft Order" next time, check your console and you'll see:
1. Full API response from `/GetDoAccount`
2. Parsed account list with all details
3. Which account user selected
4. Navigation flow to CartPage

This will help identify why those two accounts are showing and confirm they're coming from the API response.


