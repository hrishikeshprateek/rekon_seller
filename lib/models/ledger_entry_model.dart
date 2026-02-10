class LedgerEntry {
  final String? tranType;
  final String? licNo;
  final String? entryNo;
  final int? keyEntrySrNo;
  final double? drAmt;
  final int? rCount;
  final String? tranId;
  final DateTime? date;
  final double? runningAmt;
  final String? vchNumber;
  final String? tranFirm;
  final String? keyEntryNo;
  final String? tranNumber;
  final int? isEntryRecord;
  final double? crAmt;
  final String? narration; // <--- Added this field

  LedgerEntry({
    this.tranType,
    this.licNo,
    this.entryNo,
    this.keyEntrySrNo,
    this.drAmt,
    this.rCount,
    this.tranId,
    this.date,
    this.runningAmt,
    this.vchNumber,
    this.tranFirm,
    this.keyEntryNo,
    this.tranNumber,
    this.isEntryRecord,
    this.crAmt,
    this.narration, // <--- Added to constructor
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    // Support both GetAccountLedger (TitleCase) and GetOutstandingDetails (camelCase) responses
    return LedgerEntry(
      tranType: json['TranType'] as String? ?? json['trantype'] as String?,
      licNo: json['LicNo'] as String?,
      entryNo: json['EntryNo'] as String? ?? json['entryNo'] as String?,
      keyEntrySrNo: json['KeyEntrySrNo'] as int?,
      // GetOutstandingDetails returns 'amount' instead of DrAmt/CrAmt
      drAmt: _toDouble(json['DrAmt']) ?? _toDouble(json['amount']),
      rCount: json['RCount'] as int?,
      tranId: json['TranId'] as String?,
      date: _parseDate(json['Date'] as String?) ?? _parseDate(json['date'] as String?),
      runningAmt: _toDouble(json['RunningAmt']),
      vchNumber: json['VchNumber'] as String?,
      tranFirm: json['TranFirm'] as String?,
      keyEntryNo: json['KeyEntryNo'] as String? ?? json['keyentryno'] as String?,
      tranNumber: json['TranNumber'] as String?,
      isEntryRecord: json['IsEntryRecord'] as int?,
      crAmt: _toDouble(json['CrAmt']),
      // Map 'Narration' or fallbacks like 'Remarks'/'Particulars'
      narration: (json['Narration'] ?? json['Remarks'] ?? json['Particulars'])?.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'TranType': tranType,
    'LicNo': licNo,
    'EntryNo': entryNo,
    'KeyEntrySrNo': keyEntrySrNo,
    'DrAmt': drAmt,
    'RCount': rCount,
    'TranId': tranId,
    'Date': date?.toIso8601String(),
    'RunningAmt': runningAmt,
    'VchNumber': vchNumber,
    'TranFirm': tranFirm,
    'KeyEntryNo': keyEntryNo,
    'TranNumber': tranNumber,
    'IsEntryRecord': isEntryRecord,
    'CrAmt': crAmt,
    'Narration': narration, // <--- Added to JSON output
  };
}