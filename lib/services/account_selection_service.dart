import 'package:flutter/material.dart';
import '../models/account_model.dart';
/// Service to maintain selected account state across the app
/// This allows the selected account to persist even when navigating between pages
class AccountSelectionService extends ChangeNotifier {
  Account? _selectedAccount;
  Account? get selectedAccount => _selectedAccount;
  /// Set the selected account
  void setSelectedAccount(Account? account) {
    _selectedAccount = account;
    notifyListeners();
  }
  /// Clear the selected account
  void clearSelectedAccount() {
    _selectedAccount = null;
    notifyListeners();
  }
  /// Check if an account is selected
  bool get hasSelectedAccount => _selectedAccount != null;
}
