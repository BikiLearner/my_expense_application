// lib/features/expense/presentation/widget/bank_selector_dropdown.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/bank_selector_field.dart';
import '../../../bank/presentation/provider/bank_provider.dart';
import '../provider/expence_provider.dart';

/// Expense-specific wrapper around [BankSelectorField]. Keeps the
/// "restore transaction type" side effect that only the expense flow
/// needs; everything else is delegated to the reusable widget.
class BankSelectorDropdown extends StatelessWidget {
  const BankSelectorDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bankProvider = context.read<BankProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      if (bankProvider.banks.isNotEmpty &&
          expenseProvider.selectedTransaction == null) {
        expenseProvider.restoreTransactionTypeFromBanks(bankProvider.banks);
      }
    });

    return Selector2<BankProvider, ExpenseProvider, String?>(
      selector: (_, bankProvider, expenseProvider) {
        expenseProvider.restoreTransactionTypeFromBanks(bankProvider.banks);
        return expenseProvider.selectedTransaction?.id ?? 'cash';
      },
      builder: (_, selectedId, __) {
        return BankSelectorField(
          selectedBankId: selectedId,
          onChanged: (bank) =>
              context.read<ExpenseProvider>().setTransactionType(bank),
        );
      },
    );
  }
}