import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/delivery_task_model.dart';
import '../receipt_entry.dart';

class MarkCollectionPage extends StatefulWidget {
  final DeliveryTask task;

  const MarkCollectionPage({super.key, required this.task});

  @override
  State<MarkCollectionPage> createState() => _MarkCollectionPageState();
}

class _MarkCollectionPageState extends State<MarkCollectionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _remarkController = TextEditingController();

  bool _isCollected = true; // true = Collected, false = Not Collected
  String _notCollectedReason = 'Deny for Payment'; // Default reason

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall() async {
    final phoneUrl = Uri.parse('tel:+919876543210');
    if (await canLaunchUrl(phoneUrl)) {
      await launchUrl(phoneUrl);
    }
  }

  void _openReceiptEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateReceiptScreen(),
      ),
    ).then((result) {
      if (result == true) {
        // Receipt created successfully
        _completeCollection();
      }
    });
  }

  void _viewOutstanding() {
    // Navigate to outstanding screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Outstanding details will be shown here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _submitCollection() {
    if (_formKey.currentState!.validate()) {
      if (_isCollected) {
        // Open Receipt Entry
        _openReceiptEntry();
      } else {
        // Not collected - submit with reason
        if (_remarkController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter additional remarks if needed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _submitNotCollected();
      }
    }
  }

  void _completeCollection() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Collection completed for ${widget.task.partyName}'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  }

  void _submitNotCollected() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Collection marked as not received for ${widget.task.partyName}'),
        backgroundColor: Colors.orange,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending for Collection', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Party Details Card
            _buildSectionCard(
              'Party Details',
              Icons.people_rounded,
              colorScheme,
              [
                _buildInfoRow('Party Name', widget.task.partyName, isBold: true),
                const SizedBox(height: 8),
                _buildInfoRow('Address', '${widget.task.station}, ${widget.task.area}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow('Contact Person', 'Shop Owner'),
                    ),
                    IconButton(
                      icon: Icon(Icons.call, color: colorScheme.primary),
                      onPressed: _makePhoneCall,
                      tooltip: 'Call',
                    ),
                  ],
                ),
                _buildInfoRow('Mobile', '+91 98765 43210'),
              ],
            ),

            const SizedBox(height: 16),

            // Outstanding Card
            _buildSectionCard(
              'Outstanding',
              Icons.account_balance_wallet,
              colorScheme,
              [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Outstanding',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹45,500.00',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _viewOutstanding,
                      child: const Text('View Details'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildInfoRow('Bill No', 'S002010001')),
                    Expanded(
                      child: _buildInfoRow(
                        'Bill Date & Time',
                        DateFormat('dd MMM yy, hh:mm a').format(DateTime.now().subtract(const Duration(days: 15))),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Collected / Not Collected Toggle
            _buildSectionCard(
              'Collection Status',
              Icons.check_circle_outline,
              colorScheme,
              [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Receipt Entry'),
                        selected: _isCollected,
                        onSelected: (selected) {
                          setState(() => _isCollected = true);
                        },
                        selectedColor: Colors.green.withOpacity(0.2),
                        checkmarkColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Not Receipt'),
                        selected: !_isCollected,
                        onSelected: (selected) {
                          setState(() => _isCollected = false);
                        },
                        selectedColor: Colors.orange.withOpacity(0.2),
                        checkmarkColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Conditional Content
            if (_isCollected) ...[
              // Receipt Entry Flow
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 48, color: Colors.green),
                    const SizedBox(height: 12),
                    Text(
                      'Ready to Collect Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click below to proceed with receipt entry',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openReceiptEntry,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Go to Receipt Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Not Collected Flow
              _buildSectionCard(
                'Reason for Not Collecting',
                Icons.info_outline,
                colorScheme,
                [
                  Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('Deny for Payment'),
                        value: 'Deny for Payment',
                        groupValue: _notCollectedReason,
                        onChanged: (value) {
                          setState(() => _notCollectedReason = value!);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<String>(
                        title: const Text('Owner not in shop'),
                        value: 'Owner not in shop',
                        groupValue: _notCollectedReason,
                        onChanged: (value) {
                          setState(() => _notCollectedReason = value!);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Additional Remarks
              _buildSectionCard(
                'Additional Remarks',
                Icons.note,
                colorScheme,
                [
                  TextFormField(
                    controller: _remarkController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter any additional remarks (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitCollection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCollected ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isCollected ? 'Proceed to Receipt Entry' : 'Submit',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    ColorScheme colorScheme,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

