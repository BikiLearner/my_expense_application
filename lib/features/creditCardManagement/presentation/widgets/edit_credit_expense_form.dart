import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/indian_number_formatter.dart';
import '../../../../shared/enums/expense_type.dart';
import '../../../../shared/widgets/app_text_fields.dart';
import '../../../../shared/widgets/auto_complete_text_fields.dart';
import '../../../../shared/widgets/expense_type_selector_generic.dart';
import '../provider/credit_expense_provider.dart'; // Adjust path if necessary

class EditCreditExpenseForm extends StatelessWidget {
  const EditCreditExpenseForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CreditExpenseProvider>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              const Text(
                'Payment Method Cannot be changed',
                style: TextStyle(
                  color: AppColor.textSecondary, // Updated to AppColor
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
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
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  IndianNumberFormatter(),
                ],
              ),
              Selector<CreditExpenseProvider, int>(
                selector: (_, p) => p.split,
                builder: (_, split, __) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.creditCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColor.creditBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.call_split,
                          color: AppColor.creditAccent,
                        ),

                        const SizedBox(width: 10),

                        const Expanded(
                          child: Text(
                            'Split expense',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),

                        if (split > 0) ...[
                          IconButton(
                            onPressed: split > 2
                                ? () => provider.setSplit(split - 1)
                                : null,
                            icon: const Icon(Icons.remove),
                            color: Colors.white,
                          ),

                          Text(
                            '$split',
                            style: const TextStyle(
                              color: AppColor.creditAccent,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          IconButton(
                            onPressed: () => provider.setSplit(split + 1),
                            icon: const Icon(Icons.add),
                            color: Colors.white,
                          ),
                        ],

                        Switch(
                          value: split > 0,
                          onChanged: (enabled) {
                            provider.setSplit(enabled ? 2 : 0);
                          },
                        ),
                      ],
                    ),
                  );
                },
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
        Selector<CreditExpenseProvider, ExpenseType>(
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