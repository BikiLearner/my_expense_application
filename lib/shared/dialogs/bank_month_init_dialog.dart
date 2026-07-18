import 'package:flutter/material.dart';

class BankInitializeDialog {
  /// Shows the dialog and returns the user's input, or null if cancelled.
  static Future<({double surplus, double totalAdded, double currentAmount})?> show({
    required BuildContext context,
    required double previousClosing,
  }) async {
    final surplusController =
    TextEditingController(text: previousClosing.toStringAsFixed(2));
    final totalAddedController =
    TextEditingController(text: previousClosing.toStringAsFixed(2));
    final currentAmountController =
    TextEditingController(text: previousClosing.toStringAsFixed(2));

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Initialize Bank Month',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('Surplus from Previous Month', surplusController),
              _field('Total Amount Added', totalAddedController),
              _field('Current Amount', currentAmountController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    // If user presses Cancel or dismisses
    if (confirmed != true) return null;

    // Parse the values safely
    final surplusValue = double.tryParse(surplusController.text) ?? 0;
    final totalAdded = double.tryParse(totalAddedController.text) ?? 0;
    final currentAmount = double.tryParse(currentAmountController.text) ?? surplusValue;

    // Return the data back to the caller
    return (
    surplus: surplusValue,
    totalAdded: totalAdded,
    currentAmount: currentAmount,
    );
  }

  static Widget _field(
      String label,
      TextEditingController controller, {
        bool enabled = true,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}