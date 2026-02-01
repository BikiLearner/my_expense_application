import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bank_month_model.dart';
import '../providers/bank_provider.dart';

class EditBankMonthDialog extends StatefulWidget {
  final String bankId;
  final BankMonthModel month;

  const EditBankMonthDialog({
    super.key,
    required this.bankId,
    required this.month,
  });

  @override
  State<EditBankMonthDialog> createState() => _EditBankMonthDialogState();
}

class _EditBankMonthDialogState extends State<EditBankMonthDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController surplusCtrl;
  late TextEditingController incomeCtrl;
  late TextEditingController totalAddedCtrl;
  late TextEditingController currentAmountCtrl;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    surplusCtrl = TextEditingController(
      text: widget.month.surplusPreviousMonth.toStringAsFixed(2),
    );
    incomeCtrl = TextEditingController(
      text: widget.month.incomeThisMonth.toStringAsFixed(2),
    );
    totalAddedCtrl = TextEditingController(
      text: widget.month.totalAdded.toStringAsFixed(2),
    );
    currentAmountCtrl = TextEditingController(
      text: widget.month.currentAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    surplusCtrl.dispose();
    incomeCtrl.dispose();
    totalAddedCtrl.dispose();
    currentAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF64FFDA).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit_calendar,
              color: Color(0xFF64FFDA),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Edit ${widget.month.id}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _monthField(
                label: 'Surplus from Previous Month',
                controller: surplusCtrl,
              ),
              _monthField(
                label: 'Income This Month',
                controller: incomeCtrl,
              ),
              _monthField(
                label: 'Total Added',
                controller: totalAddedCtrl,
              ),
              _monthField(
                label: 'Closing Balance (Current Amount)',
                controller: currentAmountCtrl,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64FFDA),
            foregroundColor: const Color(0xFF121212),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isSaving ? null : _save,
          child: isSaving
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
              AlwaysStoppedAnimation(Color(0xFF121212)),
            ),
          )
              : const Text(
            'Save Changes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await context.read<BankProvider>().editBankMonth(
        bankId: widget.bankId,
        monthId: widget.month.id,
        surplusPreviousMonth: double.parse(surplusCtrl.text),
        incomeThisMonth: double.parse(incomeCtrl.text),
        totalAdded: double.parse(totalAddedCtrl.text),
        currentAmount: double.parse(currentAmountCtrl.text),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Month updated successfully'),
            backgroundColor: Color(0xFF64FFDA),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Widget _monthField({
    required String label,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64FFDA)),
          filled: true,
          fillColor: const Color(0xFF121212),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (double.tryParse(v) == null) return 'Invalid number';
          return null;
        },
      ),
    );
  }
}
