import 'package:flutter/material.dart';
import 'select_account_page.dart';
import 'outstanding_details_page.dart';
import '../models/account_model.dart';

/// Wrapper page that shows account selection and then navigates to Outstanding Details
class AccountOutstandingListPage extends StatefulWidget {
  const AccountOutstandingListPage({super.key});

  @override
  State<AccountOutstandingListPage> createState() => _AccountOutstandingListPageState();
}

class _AccountOutstandingListPageState extends State<AccountOutstandingListPage> {
  @override
  void initState() {
    super.initState();
    // Show account selection after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAccountSelection();
    });
  }

  Future<void> _showAccountSelection() async {
    final account = await SelectAccountPage.show(
      context,
      title: 'Select Account for Outstanding',
      showBalance: true,
    );

    if (account != null && mounted) {
      // Navigate to Outstanding Details page with selected account
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OutstandingDetailsPage(
            accountNo: account.id,
            accountName: account.name,
          ),
        ),
      );
    } else if (mounted) {
      // User cancelled, go back
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while account selection is displayed
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

