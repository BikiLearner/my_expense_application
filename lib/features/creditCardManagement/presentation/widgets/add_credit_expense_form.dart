import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/indian_number_formatter.dart';
import '../../../../shared/enums/expense_type.dart';
import '../../../../shared/widgets/app_text_fields.dart';
import '../../../../shared/widgets/auto_complete_text_fields.dart';
import '../../../../shared/widgets/expense_type_selector_generic.dart';
import 'credit_card_selector_drop_down.dart';

class AddCreditExpenseForm extends StatelessWidget {
  final bool isDesktop;

  const AddCreditExpenseForm({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CreditExpenseProvider>();

    return Container(
      color: isDesktop ? AppColor.creditSurface : AppColor.creditDark,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            const Text(
              'Add New Expense',
              style: TextStyle(
                color: AppColor.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fill in the details below',
              style: TextStyle(color: AppColor.textSecondary),
            ),
            const SizedBox(height: 24),
          ],

          /// 🔥 HEIGHT-SYNCED ROW
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// LEFT SIDE
                Expanded(
                  child: Column(
                    children: [
                      TitleAutoCompleteField(
                        initialValue: provider.title,

                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g., Groceries, Fuel',
                          labelStyle: TextStyle(color: Colors.grey[500]),
                          hintStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: const Icon(
                            Icons.title,
                            color: AppColor.creditAccent,
                          ),
                          filled: true,
                          fillColor: AppColor.creditCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColor.creditBorder,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColor.creditAccent,
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

                        dropdownColor: AppColor.creditCard,

                        suggestionTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),

                        maxHeight: 200,
                        maxWidth: 300,

                        onChanged: provider.setTitle,
                        onSelected: provider.setTitle,
                      ),
                      const SizedBox(height: 8),

                      /// 💰 AMOUNT FIELD (INDIAN FORMAT – VISUAL ONLY)
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

                        // Same colors as TitleAutoCompleteField
                        iconColor: AppColor.creditAccent,
                        fillColor: AppColor.creditCard,
                        enabledBorderColor: AppColor.creditBorder,
                        focusedBorderColor: AppColor.creditAccent,

                        textColor: Colors.white,
                        labelColor: Colors.grey,
                        hintColor: const Color(0xFF616161),
                      ),

                      const SizedBox(height: 8),
                      AppTextField(
                        controller: provider.descriptionController,
                        label: 'Description (Optional)',
                        hint: 'Add details...',
                        icon: Icons.notes,
                        // Same colors as TitleAutoCompleteField
                        iconColor: AppColor.creditAccent,
                        fillColor: AppColor.creditCard,
                        enabledBorderColor: AppColor.creditBorder,
                        focusedBorderColor: AppColor.creditAccent,

                        textColor: Colors.white,
                        labelColor: Colors.grey,
                        hintColor: const Color(0xFF616161),
                      ),
                      const SizedBox(height: 8),
                      const CreditCardSelectorDropDown(),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                /// RIGHT SIDE
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
            ),
          ),

          const SizedBox(height: 15),

          /// 🔹 ADD BUTTON
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                provider.addCreditExpense(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.creditAccent,
                foregroundColor: AppColor.creditDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline),
                  SizedBox(width: 8),
                  Text(
                    'Add Expense',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}