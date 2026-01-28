import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account_model.dart';
import '../services/account_selection_service.dart';
import 'select_account_page.dart';
import 'statement_page.dart';

/// Wrapper page that ensures the navigation flow is:
/// Home -> SelectAccountPage -> StatementPage
/// And back from StatementPage returns to SelectAccountPage
class AccountStatementWrapper extends StatefulWidget {
  const AccountStatementWrapper({Key? key}) : super(key: key);

  @override
  State<AccountStatementWrapper> createState() => _AccountStatementWrapperState();
}

class _AccountStatementWrapperState extends State<AccountStatementWrapper> {
  @override
  void initState() {
    super.initState();
    // Replace this wrapper with SelectAccountPage immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SelectAccountPageForStatement(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Custom SelectAccountPage that pushes StatementPage instead of popping
class SelectAccountPageForStatement extends StatelessWidget {
  const SelectAccountPageForStatement({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SelectAccountPage(
      title: 'Select Party for Statement',
      showBalance: true,
      onAccountSelected: (account) {
        // Save account to service
        final accountService = Provider.of<AccountSelectionService>(context, listen: false);
        accountService.setSelectedAccount(account);

        // Push StatementPage WITHOUT popping SelectAccountPage
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const StatementPage(),
          ),
        );
      },
    );
  }
}

