import 'package:flutter/material.dart';
import '../models/account_model.dart';
import 'select_account_page.dart';

/// Example page showing how to use SelectAccountPage
/// This demonstrates sending data back and forth between pages
class ExampleUsagePage extends StatefulWidget {
  const ExampleUsagePage({super.key});

  @override
  State<ExampleUsagePage> createState() => _ExampleUsagePageState();
}

class _ExampleUsagePageState extends State<ExampleUsagePage> {
  Account? _selectedAccount;

  Future<void> _pickAccount() async {
    // Open SelectAccountPage and wait for result
    final Account? result = await SelectAccountPage.show(
      context,
      title: 'Select Party',
      accountType: 'Party', // Filter to show only parties
      showBalance: true,
      selectedAccount: _selectedAccount, // Pass current selection
    );

    // If user selected an account, update state
    if (result != null) {
      setState(() {
        _selectedAccount = result;
      });

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected: ${result.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Example: Select Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display selected account
            if (_selectedAccount != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Account:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAccount!.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${_selectedAccount!.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_selectedAccount!.phone != null)
                      Text(
                        'Phone: ${_selectedAccount!.phone}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (_selectedAccount!.balance != null)
                      Text(
                        'Balance: ₹${_selectedAccount!.balance}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _selectedAccount!.balance! >= 0 ? Colors.green : colorScheme.error,
                        ),
                      ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    'No account selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Button to open SelectAccountPage
            ElevatedButton.icon(
              onPressed: _pickAccount,
              icon: const Icon(Icons.people_rounded),
              label: const Text('Select Account'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),

            const SizedBox(height: 12),

            // Clear selection button
            if (_selectedAccount != null)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedAccount = null;
                  });
                },
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear Selection'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

            const Spacer(),

            // Usage instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to use in your code:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Call SelectAccountPage.show(context)\n'
                    '2. Await the result\n'
                    '3. Use the returned Account object\n'
                    '4. User can search and select\n'
                    '5. Data is passed back automatically',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

