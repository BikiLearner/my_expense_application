import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/indian_number_formatter.dart';
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
              TitleAutoCompleteField(provider: provider),
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