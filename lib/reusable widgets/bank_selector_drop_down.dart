import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bank_model.dart';
import '../providers/bank_provider.dart';
import '../providers/expence_provider.dart';

class BankSelectorDropdown extends StatelessWidget {
  const BankSelectorDropdown({super.key});
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bankProvider = context.read<BankProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      context.read<BankProvider>().listenBanks();
      if (bankProvider.banks.isNotEmpty &&
          expenseProvider.selectedTransaction == null) {
        expenseProvider.restoreTransactionTypeFromBanks(
          bankProvider.banks,
        );
      }
    });

    return Selector2<BankProvider, ExpenseProvider, _BankSelectionState>(
      selector: (_, bankProvider, expenseProvider) {
        final banks = [cashBank, ...bankProvider.banks];
        expenseProvider.restoreTransactionTypeFromBanks(
          bankProvider.banks,
        );
        final selectedId =
            expenseProvider.selectedTransaction?.id ?? 'cash';

        final selectedBank = banks.firstWhere(
              (b) => b.id == selectedId,
          orElse: () => cashBank,
        );

        return _BankSelectionState(banks, selectedBank);
      },
      builder: (_, state, __) {
        return DropdownButtonFormField<BankModel>(
          value: state.selectedBank,
          isExpanded: true,
          dropdownColor: const Color(0xFF2C2C2C),

          decoration: InputDecoration(
            labelText: 'Payment Method',
            labelStyle: TextStyle(color: Colors.grey[500]),
            hintText: 'Select bank or cash',
            hintStyle: TextStyle(color: Colors.grey[700]),
            prefixIcon: const Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF64FFDA),
            ),
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFF3C3C3C), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFF64FFDA), width: 2),
            ),
          ),

          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
          ),

          items: state.banks.map((bank) {
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
                  Row(
                    children: [
                      // 🏦 Title / Bank Name
                      Text(
                        bank.bankName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(width: 8),

                      // 💰 Amount
                      Selector<BankProvider, _BankBalanceView>(
                        selector: (_, provider) => _BankBalanceView(
                          bank,
                          bank.id == 'cash'
                              ? 0.0
                              : provider.getCurrentMonthBalance(bank.id),
                        ),
                        builder: (_, state, __) {
                          return Text(
                            '₹${state.balance.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                          );
                        },
                      ),

                    ],
                  )

                ],
              ),
            );
          }).toList(),

          onChanged: (bank) {
            if (bank != null) {
              context.read<ExpenseProvider>().setTransactionType(bank);
            }
          },
        );
      },
    );
  }
}


class _BankBalanceView {
  final BankModel bank;
  final double balance;

  const _BankBalanceView(this.bank, this.balance);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _BankBalanceView &&
              bank.id == other.bank.id &&
              balance == other.balance;

  @override
  int get hashCode => bank.id.hashCode ^ balance.hashCode;
}


class _BankSelectionState {
  final List<BankModel> banks;
  final BankModel selectedBank;

  const _BankSelectionState(this.banks, this.selectedBank);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _BankSelectionState &&
              banks == other.banks &&
              selectedBank.id == other.selectedBank.id;

  @override
  int get hashCode => banks.hashCode ^ selectedBank.id.hashCode;
}
