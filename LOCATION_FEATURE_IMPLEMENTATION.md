# Location Selection Feature - Implementation Summary

## Overview
Implemented a location selection feature in the Select Account Page that allows users to add location data for accounts that don't have a location set. When an account lacks location information, instead of a disabled "Navigate" button, users now see an "Add Location" button that opens a bottom sheet with a map picker.

## Features Implemented

### 1. **Location Picker Bottom Sheet** (`location_picker_sheet.dart`)
A new reusable widget that provides:
- **Interactive Map View**: Users can tap on the map to select any location
- **Current Location Detection**: "Get Current Location" button to auto-locate the device
- **Address Auto-fill**: Reverse geocoding to automatically populate address from coordinates
- **Manual Address Editing**: Users can view and modify the address
- **Location Display**: Shows latitude and longitude coordinates in real-time
- **API Integration**: Calls the `UpdateLocation` API endpoint to save location data

### 2. **Updated Select Account Page** (`select_account_page.dart`)
Modified the account card UI to:
- Import the new location picker sheet
- Display conditional buttons:
  - If account **has location**: Shows "Navigate" button (existing behavior)
  - If account **lacks location**: Shows "Add Location" button
- Handle location updates without reloading the entire list
- Integrate with the new `_showLocationPicker` method

### 3. **API Integration**
Calls the following endpoint when saving a location:
```
POST /UpdateLocation
Headers:
  - Authorization: Bearer {JWT_TOKEN}
  - Content-Type: application/json
  - package_name: com.reckon.reckonbiz

Payload:
{
  "latitude": "28.613939",
  "longitude": "77.209024",
  "googleAddress": "India Gate, New Delhi, India",
  "acIdCol": 4314602
}

Response:
{
  "success": true,
  "message": "Location Updated Successfully",
  "rs": 1,
  "data": {
    "latitude": "28.613939",
    "longitude": "77.209024",
    "googleAddress": "India Gate, New Delhi, India",
    "acIdCol": 4314602
  }
}
```

## Technical Details

### Dependencies Added
- `geocoding: ^3.0.0` - For reverse geocoding (coordinates to address)

### Key Methods Added

**In `_SelectAccountPageState`:**
```dart
void _showLocationPicker(BuildContext context, Account account)
```
Opens the location picker bottom sheet and handles account updates.

**In `_LocationPickerSheetState`:**
- `_getCurrentLocation()` - Fetches device's current location
- `_getAddressFromCoordinates()` - Reverse geocodes coordinates to get address
- `_onMapTap()` - Handles map taps to select new location
- `_updateLocation()` - Calls the UpdateLocation API

### UI Flow

1. **Account Card Display**
   - Without location: Shows "Add Location" button
   - With location: Shows "Navigate" button (existing)

2. **Location Picker Sheet**
   - Shows interactive map centered at device location or default (Delhi)
   - Displays current coordinates
   - Text field to enter/edit address
   - "Get Current Location" button for quick location capture
   - "Save Location" button to submit
   - "Cancel" button to close without saving

3. **Success Flow**
   - API call succeeds → Account is updated in memory
   - List is refreshed to show updated account
   - Success message displayed
   - Bottom sheet automatically closes

4. **Error Handling**
   - Network errors caught and displayed
   - Invalid inputs (empty address) prevented
   - Permission denied handled gracefully
   - All async operations managed with loading states

### Account Model Updates
The `Account` model already had the necessary fields:
- `latitude: double?`
- `longitude: double?`
- `acIdCol: int?` (used in API payload)

## User Experience

1. User taps "Add Location" button on account card
2. Bottom sheet opens with map and location form
3. User can:
   - Use current device location (tap "Get Current Location")
   - Manually tap on map to select location
   - Edit the auto-populated address
4. User taps "Save Location"
5. Location is saved via API
6. Account card is updated to show "Navigate" button
7. User can now navigate to the location using Google Maps

## Error Handling

- **Permission Denied**: Shows user-friendly error message
- **Location Service Unavailable**: Defaults to Delhi, allows manual selection
- **Network Errors**: Displays API error message
- **Invalid Input**: Prevents saving without address
- **Geocoding Failure**: Allows manual address entry

## Future Enhancements (Optional)

1. Search for addresses instead of just map tapping
2. Save multiple location points for an account
3. Location history
4. Offline location caching
5. Integration with Google Places API for better address suggestions

