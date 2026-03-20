# Mutually Exclusive Button Logic - Implementation

## Overview
Implemented logic to make the Add/Update button and Quick Quantity Adjuster (- / +) buttons mutually exclusive based on the `ShowIncreaseDecreaseButton_SalesMan` flag.

## Implementation

**File**: `/lib/pages/order_entry_page.dart`

### Logic:

```
IF ShowIncreaseDecreaseButton_SalesMan = TRUE
  ├─ Hide: Add/Update button
  └─ Show: -/+ Quick Quantity Adjuster
  
ELSE (ShowIncreaseDecreaseButton_SalesMan = FALSE)
  ├─ Show: Add/Update button
  └─ Hide: -/+ Quick Quantity Adjuster
```

## Product Card Layouts

### When `ShowIncreaseDecreaseButton_SalesMan` = **TRUE**:
```
┌─ Product Card ─────────────┐
│ Product Name               │
│ Details...                 │
│                            │
│ [- 2 +] (Quick Adjuster)   │ ✅ VISIBLE
│ Stock: 10                  │
└────────────────────────────┘
```
**User can**: Quickly add/remove 1 quantity at a time  
**User cannot**: Open customization bottom sheet

### When `ShowIncreaseDecreaseButton_SalesMan` = **FALSE**:
```
┌─ Product Card ─────────────┐
│ Product Name               │
│ Details...                 │
│                            │
│ [ADD/UPDATE Button]        │ ✅ VISIBLE
│ Stock: 10                  │
└────────────────────────────┘
```
**User can**: Open bottom sheet for customization  
**User cannot**: Quick adjust quantity

## Code Changes

The button/adjuster section now uses conditional rendering:

```dart
// If ShowIncreaseDecreaseButton_SalesMan is TRUE: Show only -/+ button, hide Add/Update
if (context.watch<SalesmanFlagsService>().flags?.showIncreaseDecreaseButtonSalesMan ?? false)
  ...[
    // -/+ Quick Quantity Adjuster shown
    QuickQuantityAdjuster(...),
  ]
else
  // If ShowIncreaseDecreaseButton_SalesMan is FALSE: Show Add/Update button, hide -/+
  ...[
    // Add/Update Button shown
    SizedBox(
      height: 32,
      child: qty == 0 ? OutlinedButton(...ADD...) : FilledButton(...UPDATE...),
    ),
  ],
```

## Feature Behavior

### Scenario 1: Quick Add Mode (Flag = TRUE)
- No Add/Update button visible
- Only - / + buttons available
- Perfect for users who want quick quantity adjustments
- No bottom sheet customization available

### Scenario 2: Detailed Add Mode (Flag = FALSE)
- Add/UPDATE button visible
- No - / + buttons
- Users can click button to open bottom sheet
- Can customize price, discount, scheme, etc.
- Use for users who need detailed product configuration

## Compilation Status

✅ **Zero Errors**  
✅ **No Breaking Changes**  
✅ **Production Ready**

---

## User Experience Flow

### With Quick Add Mode (ShowIncreaseDecreaseButton_SalesMan = TRUE):
1. User sees product card with - / + buttons
2. User clicks + to add 1 quantity at a time
3. Each click directly calls API to update cart
4. Quick, minimal UI - no bottom sheet needed

### With Detailed Add Mode (ShowIncreaseDecreaseButton_SalesMan = FALSE):
1. User sees product card with ADD/UPDATE button
2. User clicks button to open bottom sheet
3. User customizes quantity, price, discount, scheme, remarks
4. User clicks ADD/UPDATE to save to cart
5. Detailed configuration option

---

**Status**: 🎉 **IMPLEMENTATION COMPLETE AND TESTED**

The product cards now show either the quick quantity adjuster OR the Add/Update button based on the tenant's configuration flag, providing two distinct workflows for different user needs.

