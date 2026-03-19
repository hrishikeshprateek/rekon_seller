# Bottom Sheet Flags Implementation - Order Entry Page

## Summary
Applied dynamic visibility controls to the product add/update bottom sheet in `order_entry_page.dart` based on salesman flags stored in SharedPreferences.

## Changes Made

### 1. **Free Quantity Field**
- **Flag**: `showFreeQtySalesMan` (ShowFreeQty_SalesMan)
- **Behavior**: Field only shows if flag is `true`
- **Code Location**: Line ~1646

```dart
if (context.watch<SalesmanFlagsService>().flags?.showFreeQtySalesMan ?? false)
  ...[
    rowField('Free Quantity', freeQtyController, TextInputType.number),
    const SizedBox(height: 12),
  ],
```

### 2. **Scheme Field (Two Input Boxes)**
- **Flag**: `showSchemeSalesMan` (ShowScheme_SalesMan)
- **Behavior**: Entire scheme section (both input boxes with +) hides if flag is `false`
- **Code Location**: Line ~1652

```dart
if (context.watch<SalesmanFlagsService>().flags?.showSchemeSalesMan ?? false)
  ...[
    Row(
      children: [
        // Scheme input boxes...
      ],
    ),
    const SizedBox(height: 12),
  ],
```

### 3. **Price Field**
- **Flag**: `enablePriceSalesMan` (EnablePrice_SalesMan)
- **Behavior**: Price input field only shows if flag is `true`
- **Code Location**: Line ~1687

```dart
if (context.watch<SalesmanFlagsService>().flags?.enablePriceSalesMan ?? false)
  ...[
    rowField('Price', priceController, const TextInputType.numberWithOptions(decimal: true)),
    const SizedBox(height: 12),
  ],
```

### 4. **Discount (Pcs) Field**
- **Flag**: `showDiscPcsSalesMan` (ShowDiscPcs_SalesMan)
- **Behavior**: Field only shows if flag is `true`
- **Code Location**: Line ~1694

```dart
if (context.watch<SalesmanFlagsService>().flags?.showDiscPcsSalesMan ?? false)
  ...[
    rowFieldWithAmt('Discount (Pcs)', discPcsController, preview?.discAmt ?? 0.0),
    const SizedBox(height: 12),
  ],
```

### 5. **Discount (%) Field**
- **Flag**: `showDiscPerSalesMan` (ShowDiscPer_SalesMan)
- **Behavior**: Field only shows if flag is `true`
- **Code Location**: Line ~1700

```dart
if (context.watch<SalesmanFlagsService>().flags?.showDiscPerSalesMan ?? false)
  ...[
    rowFieldWithAmt('Discount (%)', discPerController, preview?.disc1Amt ?? 0.0),
    const SizedBox(height: 12),
  ],
```

### 6. **Add. Discount (%) Field**
- **Flag**: `showdisc1perSalesman` (showdisc1per_Salesman)
- **Behavior**: Field only shows if flag is `true`
- **Code Location**: Line ~1706

```dart
if (context.watch<SalesmanFlagsService>().flags?.showdisc1perSalesman ?? false)
  ...[
    rowFieldWithAmt('Add. Discount (%)', addDiscPerController, preview?.disc2Amt ?? 0.0),
    const SizedBox(height: 12),
  ],
```

### 7. **Remark Field**
- **Flag**: `showItemRemarkSalesMan` (ShowItemRemark_SalesMan)
- **Behavior**: Remark input field only shows if flag is `true`
- **Code Location**: Line ~1714

```dart
if (context.watch<SalesmanFlagsService>().flags?.showItemRemarkSalesMan ?? false)
  ...[
    Text('Add Remark (Optional)', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    TextField(
      controller: remarkController,
      maxLength: 200,
      maxLines: 2,
      style: textTheme.bodyMedium,
      decoration: _fieldDeco(colorScheme).copyWith(
        hintText: 'Type here...',
        contentPadding: const EdgeInsets.all(12),
        counterText: '',
      ),
    ),
    const SizedBox(height: 24),
  ]
else
  const SizedBox(height: 20),
```

### 8. **Summary Card (Goods Value, Scheme Value, Discount Value, GST, Net Value)**
- **Flag**: `showadddetailsbottomsheetSalesMan` (Showadddetailsbottomsheet_SalesMan)
- **Behavior**: Entire summary section only shows if flag is `true` (defaults to `true`)
- **Code Location**: Line ~1730

```dart
if (context.watch<SalesmanFlagsService>().flags?.showadddetailsbottomsheetSalesMan ?? true)
  ...[
    Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        // Summary card content...
      ),
    ),
    const SizedBox(height: 24),
  ],
```

## Flag Mapping Reference

| Field | API Flag Name | Model Property | Default |
|-------|---------------|-----------------|---------|
| Free Quantity | ShowFreeQty_SalesMan | showFreeQtySalesMan | false |
| Scheme (2 boxes) | ShowScheme_SalesMan | showSchemeSalesMan | false |
| Price | EnablePrice_SalesMan | enablePriceSalesMan | false |
| Discount (Pcs) | ShowDiscPcs_SalesMan | showDiscPcsSalesMan | false |
| Discount (%) | ShowDiscPer_SalesMan | showDiscPerSalesMan | false |
| Add. Discount (%) | showdisc1per_Salesman | showdisc1perSalesman | false |
| Remark | ShowItemRemark_SalesMan | showItemRemarkSalesMan | false |
| Summary Details | Showadddetailsbottomsheet_SalesMan | showadddetailsbottomsheetSalesMan | true |

## How It Works

1. **Runtime Evaluation**: The `context.watch<SalesmanFlagsService>().flags?.fieldName ?? defaultValue` pattern ensures:
   - Flags are watched for real-time updates
   - Null-safe access to flag properties
   - Default behavior if flags service is not initialized

2. **Conditional Rendering**: Uses Dart's spread operator (`...[]`) to conditionally include widgets:
   - If flag is `true`: Widget is rendered
   - If flag is `false`: Widget is completely removed from the widget tree

3. **API Call**: Flags are fetched from:
   - **Endpoint**: `/GetSalesmanFlags`
   - **Base URL**: `http://mobileappsandbox.reckonsales.com:8080/reckon-biz/api/reckonpwsorder`
   - **Stored**: SharedPreferences cache for offline access

## Testing Checklist

- [ ] Verify free quantity field shows/hides based on `ShowFreeQty_SalesMan`
- [ ] Verify scheme input boxes show/hide based on `ShowScheme_SalesMan`
- [ ] Verify price field shows/hides based on `EnablePrice_SalesMan`
- [ ] Verify discount (pcs) field shows/hides based on `ShowDiscPcs_SalesMan`
- [ ] Verify discount (%) field shows/hides based on `ShowDiscPer_SalesMan`
- [ ] Verify add. discount (%) field shows/hides based on `showdisc1per_Salesman`
- [ ] Verify remark field shows/hides based on `ShowItemRemark_SalesMan`
- [ ] Verify summary card shows/hides based on `Showadddetailsbottomsheet_SalesMan`
- [ ] Test with different flag combinations
- [ ] Verify bottom sheet spacing adjusts correctly when fields are hidden

## Example Flag Configuration

```json
{
  "ShowFreeQty_SalesMan": true,
  "ShowScheme_SalesMan": true,
  "EnablePrice_SalesMan": false,
  "ShowDiscPcs_SalesMan": true,
  "ShowDiscPer_SalesMan": true,
  "showdisc1per_Salesman": true,
  "ShowItemRemark_SalesMan": true,
  "Showadddetailsbottomsheet_SalesMan": true
}
```

## Implementation Status
✅ Completed - All fields now respect salesman flags

