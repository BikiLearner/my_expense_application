import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/enums/expense_type.dart';
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
              TitleAutoCompleteField(
                initialValue: provider.title,

                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Groceries, Fuel',
                  labelStyle: TextStyle(color: Colors.grey[500]),
                  hintStyle: TextStyle(color: Colors.grey[700]),
                  prefixIcon: const Icon(
                    Icons.title,
                    color: Color(0xFF64FFDA),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF3C3C3C),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF64FFDA),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),

                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),

                dropdownColor: const Color(0xFF2C2C2C),

                suggestionTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),

                maxHeight: 200,
                maxWidth: 300,

                onChanged: provider.setTitle,
                onSelected: provider.setTitle,
              ),
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
        Selector<ExpenseProvider, ExpenseType>(
          selector: (_, p) => p.selectedType,
          builder: (_, selectedType, __) {
            return ExpenseTypeSelector(
              selectedType: selectedType,
              onChanged: provider.setExpenseType,
            );
          },
        )
      ],
    );
  }
}
