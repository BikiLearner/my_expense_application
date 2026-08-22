// lib/shared/widgets/bank_selector_field.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/bank/data/model/bank_model.dart';
import '../../features/bank/presentation/provider/bank_provider.dart';

/// Generic "pay from" bank/cash picker.
///
/// Fully controlled: it doesn't own selection state and doesn't know
/// about any specific feature provider (expense, credit payment, etc).
/// The caller passes the currently selected bank id and gets a callback
/// when the user picks a different one, so this can be dropped into any
/// screen that needs a bank dropdown.
class BankSelectorField extends StatelessWidget {
  const BankSelectorField({
    super.key,
    required this.selectedBankId,
    required this.onChanged,
    this.includeCash = true,
    this.showBalance = true,
    this.label = 'Payment Method',
    this.hintText = 'Select bank or cash',
    this.validator,
  });

  final String? selectedBankId;
  final ValueChanged<BankModel> onChanged;
  final bool includeCash;
  final bool showBalance;
  final String label;
  final String hintText;
  final String? Function(BankModel?)? validator;

  @override
  Widget build(BuildContext context) {
    return Selector<BankProvider, List<BankModel>>(
      selector: (_, provider) => provider.banks,
      builder: (_, banks, __) {
        final allBanks = includeCash ? [cashBank, ...banks] : banks;
        if (allBanks.isEmpty) {
          return const SizedBox.shrink();
        }

        final selectedBank = allBanks.firstWhere(
              (b) => b.id == selectedBankId,
          orElse: () => allBanks.first,
        );

        return DropdownButtonFormField<BankModel>(
          initialValue: selectedBank,
          isExpanded: true,
          dropdownColor: const Color(0xFF2C2C2C),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.grey[500]),
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[700]),
            prefixIcon: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF64FFDA),
            ),
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3C3C3C), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF64FFDA), width: 2),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
          items: allBanks.map((bank) {
            return DropdownMenuItem<BankModel>(
              value: bank,
              child: Row(
                children: [
                  Icon(
                    bank.id == 'cash'
                        ? Icons.money_rounded
                        : Icons.account_balance_rounded,
                    size: 20,
                    color: bank.id == 'cash'
                        ? const Color(0xFF64FFDA)
                        : Colors.white70,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bank.bankName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showBalance) ...[
                    const SizedBox(width: 8),
                    _BalanceLabel(bank: bank),
                  ],
                ],
              ),
            );
          }).toList(),
          validator: validator,
          onChanged: (bank) {
            if (bank != null) onChanged(bank);
          },
        );
      },
    );
  }
}

class _BalanceLabel extends StatelessWidget {
  const _BalanceLabel({required this.bank});
  final BankModel bank;

  @override
  Widget build(BuildContext context) {
    return Selector<BankProvider, double>(
      selector: (_, provider) =>
      bank.id == 'cash' ? 0.0 : provider.getCurrentMonthBalance(bank.id),
      builder: (_, balance, __) {
        return Text(
          '₹${balance.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
        );
      },
    );
  }
}