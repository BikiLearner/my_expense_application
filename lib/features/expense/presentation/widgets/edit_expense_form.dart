import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/app_text_fields.dart';
import '../../../../shared/widgets/auto_complete_text_fields.dart';
import '../../../../shared/widgets/expense_type_selector_generic.dart';
import '../provider/expence_provider.dart';

class EditExpenseForm extends StatelessWidget {
  const EditExpenseForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 8),

              // Selector<ExpenseProvider, bool>(
              //   selector: (_, p) => p.isCurrentMonth,
              //   builder: (context, isCurrentMonth, _)
              //   {
              //     return Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Opacity(
              //           opacity: isCurrentMonth ? 1 : 0.5,
              //           child: IgnorePointer(
              //             ignoring: !isCurrentMonth,
              //             child: BankSelectorDropdown(),
              //           ),
              //         ),
              //         if (!isCurrentMonth) ...[
              //           const SizedBox(height: 6),
              //           const Text(
              //             '❌ Bank cannot be edited for past expenses Apun may\n itna aaukat nahi hai ki hum kar paya aa wala solly',
              //             style: TextStyle(
              //               color: Colors.redAccent,
              //               fontSize: 12,
              //               fontWeight: FontWeight.w500,
              //             ),
              //           ),
              //         ],
              //       ],
              //     );
              //   },
              // ),
              const SizedBox(height: 16),
              TitleAutoCompleteField(provider: provider),
              const SizedBox(height: 16),
              AppTextField(
                controller: provider.amountController,
                label: 'Amount',
                hint: 'Enter amount',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: provider.descriptionController,
                label: 'Description (Optional)',
                hint: 'Add details...',
                icon: Icons.notes,
                maxLines: 3,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ExpenseTypeSelector(provider: provider),
      ],
    );
  }
}
