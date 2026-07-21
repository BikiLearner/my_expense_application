import 'package:expence_app/features/expense/presentation/widgets/bank_selector_drop_down.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/indian_number_formatter.dart';
import '../../../../shared/enums/expense_type.dart';
import '../../../../shared/widgets/app_text_fields.dart';
import '../../../../shared/widgets/auto_complete_text_fields.dart';
import '../../../../shared/widgets/expense_type_selector_generic.dart';
import '../provider/expence_provider.dart';

class AddExpenseForm extends StatelessWidget {
  final bool isDesktop;

  const AddExpenseForm({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    return Container(
      color: isDesktop ? const Color(0xFF1E1E1E) : const Color(0xFF1A1A1A),
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            const Text(
              'Add New Expense',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details below',
              style: TextStyle(color: Colors.grey[500]),
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
                      ),

                      const SizedBox(height: 8),
                      AppTextField(
                        controller: provider.descriptionController,
                        label: 'Description (Optional)',
                        hint: 'Add details...',
                        icon: Icons.notes,
                      ),
                      const SizedBox(height: 8),
                      const BankSelectorDropdown(),
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
                /// RIGHT SIDE
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
                provider.addExpense(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: const Color(0xFF121212),
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
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
