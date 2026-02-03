import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../enums/indian_number_formatter.dart';
import '../models/bank_model.dart';
import '../providers/bank_provider.dart';

class BankTransferDialog extends StatefulWidget {
  final BankModel currentBank;

  const BankTransferDialog({
    super.key,
    required this.currentBank,
  });

  @override
  State<BankTransferDialog> createState() => _BankTransferDialogState();
}

class _BankTransferDialogState extends State<BankTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String? _selectedTargetBankId;

  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bankProvider = context.read<BankProvider>();

    final availableBanks = bankProvider.banks
        .where((b) => b.id != widget.currentBank.id)
        .toList();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: _header(),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sourceBankCard(bankProvider),
              const SizedBox(height: 20),
              _targetBankSection(availableBanks, bankProvider),
              const SizedBox(height: 16),
              _amountField(bankProvider),
              const SizedBox(height: 12),
              _descriptionField(),
            ],
          ),
        ),
      ),
      actions: _actions(bankProvider, availableBanks),
    );
  }

  // ───────────────── HEADER ─────────────────

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF64FFDA).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.swap_horiz_rounded,
            color: Color(0xFF64FFDA),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Transfer Money',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────── SOURCE BANK ─────────────────

  Widget _sourceBankCard(BankProvider bankProvider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF64FFDA).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_rounded,
                color: Color(0xFF64FFDA),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'From: ${widget.currentBank.bankName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Selector<BankProvider, double>(
            selector: (_, p) =>
                p.getCurrentMonthBalance(widget.currentBank.id),
            builder: (_, balance, __) {
              return Text(
                'Available: ₹${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: balance > 0
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ───────────────── TARGET BANK ─────────────────
  Widget _targetBankSection(
      List<BankModel> banks,
      BankProvider bankProvider,
      ) {
    if (banks.isEmpty) {
      return _noBankWarning();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 Dropdown (bank name only)
        DropdownButtonFormField<String>(
          value: _selectedTargetBankId,
          dropdownColor: const Color(0xFF1E1E1E),
          decoration: _inputDecoration(
            'Select destination bank',
            Icons.account_balance_wallet_rounded,
          ),
          items: banks.map((bank) {
            return DropdownMenuItem<String>(
              value: bank.id,
              child: Text(
                bank.bankName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (id) {
            setState(() {
              _selectedTargetBankId = id;
            });
          },
          validator: (v) =>
          v == null ? 'Please select a destination bank' : null,
        ),

        /// 🔹 Selected bank balance (below dropdown)
        if (_selectedTargetBankId != null) ...[
          const SizedBox(height: 8),
          Selector<BankProvider, double>(
            selector: (_, p) =>
                p.getCurrentMonthBalance(_selectedTargetBankId!),
            builder: (_, balance, __) {
              return Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 14,
                    color: Color(0xFF64FFDA),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Available balance: ₹${balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }


  Widget _noBankWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent),
      ),
      child: const Text(
        'No other banks available.\nPlease add another bank first.',
        style: TextStyle(color: Colors.orangeAccent),
      ),
    );
  }

  // ───────────────── INPUTS ─────────────────

  Widget _amountField(BankProvider bankProvider) {
    return TextFormField(
      controller: _amountCtrl,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        IndianNumberFormatter(),
      ],
      style: const TextStyle(color: Colors.white),
      decoration:
      _inputDecoration('Transfer Amount', Icons.currency_rupee),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter amount';

        final amount = double.tryParse(v.replaceAll(',', ''));
        if (amount == null || amount <= 0) {
          return 'Invalid amount';
        }

        final balance =
        bankProvider.getCurrentMonthBalance(widget.currentBank.id);
        if (amount > balance) return 'Insufficient balance';

        return null;
      },
    );
  }

  Widget _descriptionField() {
    return TextFormField(
      controller: _descriptionCtrl,
      maxLines: 2,
      style: const TextStyle(color: Colors.white),
      decoration:
      _inputDecoration('Description (optional)', Icons.notes),
    );
  }

  // ───────────────── ACTIONS ─────────────────

  List<Widget> _actions(
      BankProvider bankProvider,
      List<BankModel> availableBanks,
      ) {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
      ),
      ElevatedButton(
        onPressed:
        (_isLoading || availableBanks.isEmpty) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF64FFDA),
          foregroundColor: const Color(0xFF121212),
        ),
        child: _isLoading
            ? const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Text(
          'Transfer',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount =
      double.parse(_amountCtrl.text.replaceAll(',', ''));

      await context.read<BankProvider>().transferBetweenBanks(
        context: context,
        fromBankId: widget.currentBank.id,
        toBankId: _selectedTargetBankId ?? '',
        amount: amount,
        description: _descriptionCtrl.text.trim().isEmpty
            ? 'Bank transfer'
            : _descriptionCtrl.text.trim(),
      );

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ───────────────── DECORATION ─────────────────

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF64FFDA)),
      filled: true,
      fillColor: const Color(0xFF121212),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
