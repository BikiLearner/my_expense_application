import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'enums/expense_type.dart';
import 'enums/transaction_type_enum.dart';
import 'models/expense_items.dart';
import 'providers/expence_provider.dart';
import 'history_screen.dart';
class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedDate = context.select<ExpenseProvider, DateTime>(
          (p) => p.selectedDate
    );

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Color(0xFF64FFDA)),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd MMM yyyy').format(selectedDate),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600
              )
            )
          ]
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Color(0xFF64FFDA)),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen())
              );
            }
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Color(0xFF64FFDA)),
            tooltip: 'Select Date',
            onPressed: () => _selectDate(context)
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF64FFDA)),
            tooltip: 'Add Category',
            onPressed: () {
              context.read<ExpenseProvider>().showAddCategoryDialog(context);
            }
          ),
          const SizedBox(width: 8)
        ]
      ),
      body: isDesktop ? _buildDesktopLayout(context) : _buildMobileLayout(context)
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();

    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now()
    );

    if (picked != null && picked != provider.selectedDate) {
      provider.setSelectedDate(picked);
    }
  }


  // 📱 Mobile & Tablet Layout (Stacked)
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Expense List
        Expanded(child: _buildExpenseList(context)),
        // Input Form
        _buildInputForm(context, isDesktop: false)
      ]
    );
  }

  // 🖥️ Desktop Layout (Side by Side)
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left: Expense List
        Expanded(
          flex: 3,
          child: _buildExpenseList(context)
        ),
        // Right: Input Form
        Container(
          width: 400,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            border: Border(
              left: BorderSide(color: Color(0xFF2C2C2C), width: 1)
            )
          ),
          child: _buildInputForm(context, isDesktop: true)
        )
      ]
    );
  }

  // 📋 Expense List Widget
  Widget _buildExpenseList(BuildContext context) {
    return Selector<ExpenseProvider, bool>(
      selector: (_, p) => p.isLoading,
      builder: (_, isLoading, __) {
        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF64FFDA)
            )
          );
        }

        return Selector<ExpenseProvider, List<ExpenseItem>>(
          selector: (_, p) => p.cachedExpenses,
          builder: (_, expenses, __) {
            if (expenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 80, color: Colors.grey[700]),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses yet',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 18,
                        fontWeight: FontWeight.w500
                      )
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first expense below',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14
                      )
                    )
                  ]
                )
              );
            }

            return Selector<ExpenseProvider, double>(
              selector: (_, p) => p.totalExpense,
              builder: (_, total, __) {
                return Column(
                  children: [
                    // Total Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A5F), Color(0xFF2A5298)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4)
                          )
                        ]
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Expenses',
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 14
                                )
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold
                                )
                              )
                            ]
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)
                            ),
                            child: Text(
                              '${expenses.length} items',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600
                              )
                            )
                          )
                        ]
                      )
                    ),

                    // Expense List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: expenses.length,
                        itemBuilder: (_, i) {
                          final expense = expenses[i];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF2C2C2C)
                              )
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: expense.type.color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Icon(
                                  expense.type.icon,
                                  color: expense.type.color
                                )
                              ),
                              title: Text(
                                expense.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600
                                )
                              ),
                              subtitle: expense.description.isNotEmpty
                                  ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  expense.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey[500]
                                  )
                                )
                              )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₹${expense.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF64FFDA),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                  IconButton(
                                    icon:
                                    const Icon(Icons.edit_outlined),
                                    color: Colors.orangeAccent,
                                    onPressed: () =>
                                        _openEditExpense(context, expense)
                                  ),
                                  IconButton(
                                    icon:
                                    const Icon(Icons.delete_outline),
                                    color: Colors.redAccent,
                                    onPressed: () =>
                                        _showDeleteConfirmation(
                                            context, expense)
                                  )
                                ]
                              )
                            )
                          );
                        }
                      )
                    )
                  ]
                );
              }
            );
          }
        );
      }
    );
  }


  void _openEditExpense(BuildContext context, ExpenseItem expense) {
    final provider = context.read<ExpenseProvider>();

    // Pre-fill form
    provider.titleController.text = expense.title;
    provider.amountController.text = expense.amount.toString();
    provider.descriptionController.text = expense.description;
    provider.setExpenseType(expense.type);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
        ),
        title: const Text(
          'Edit Expense',
          style: TextStyle(color: Colors.white)
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditFormFields(context)
              ]
            )
          )
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearForm();
              Navigator.pop(dialogContext);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[500])
            )
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: const Color(0xFF121212)
            ),
            onPressed: () async {
              await provider.editExpense(
                docId: expense.id,
                oldAmount: expense.amount,
                oldType: expense.type,
                oldDate: expense.createdAt
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text(
              'Update Expense',
              style: TextStyle(fontWeight: FontWeight.bold)
            )
          )
        ]
      )
    );
  }

  Widget _buildEditFormFields(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    return Column(
      children: [
        Row(
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
                  _TransactionTypeChips(),
                  const SizedBox(height: 16),
                  _buildTitleAutoComplete(context, provider.titleController),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: provider.amountController,
                    label: 'Amount',
                    icon: Icons.currency_rupee,
                    hint: 'e.g., 500',
                    keyboardType: TextInputType.number
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: provider.descriptionController,
                    label: 'Description (Optional)',
                    icon: Icons.notes,
                    hint: 'Add details...',
                    maxLines: 3
                  )
                ]
              )
            ),
            const SizedBox(width: 12),
            _ExpenseTypeSelector()
          ]
        )
      ]
    );
  }

  // ✏️ Input Form Widget
  Widget _buildInputForm(BuildContext context, {required bool isDesktop}) {
    final provider = context.read<ExpenseProvider>();

    return Container(
      color: isDesktop ? const Color(0xFF1E1E1E) : const Color(0xFF1A1A1A),
      child: SingleChildScrollView(
        child: Padding(
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
                    fontWeight: FontWeight.bold
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in the details below',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14
                  )
                ),
                const SizedBox(height: 24)
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Left: Inputs
                  Expanded(
                    child: Column(
                      children: [

                        _buildTitleAutoComplete(context, provider.titleController),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: provider.amountController,
                          label: 'Amount',
                          icon: Icons.currency_rupee,
                          hint: 'e.g., 500',
                          keyboardType: TextInputType.number
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: provider.descriptionController,
                          label: 'Description (Optional)',
                          icon: Icons.notes,
                          hint: 'Add details...',
                          maxLines: 3
                        ),
                        const SizedBox(height: 16),
                        _TransactionTypeChips(),

                      ]
                    )
                  ),
                  const SizedBox(width: 12),
                  // 🔹 Right: Expense Type Selector
                  _ExpenseTypeSelector()
                ]
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: provider.addExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64FFDA),
                    foregroundColor: const Color(0xFF121212),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    )
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Add Expense',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold
                        )
                      )
                    ]
                  )
                )
              )
            ]
          )
        )
      )
    );
  }

  // 🎨 Custom Text Field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey[500]),
        hintStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Icon(icon, color: const Color(0xFF64FFDA)),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3C3C3C), width: 1)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF64FFDA), width: 2)
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16
        )
      )
    );
  }

  Widget _buildTitleAutoComplete(
      BuildContext context,
      TextEditingController controller
      ) {
    // Force rebuild when text changes
   
    return Selector<ExpenseProvider, int>(
        selector: (_, p) => p.autoCompleteKey,
        builder: (context, autoKey, _) {
          return Selector<ExpenseProvider, List<String>>(
              selector: (_, p) => p.cachedCategories,
              builder: (context, cachedCategories, __) {
        return Autocomplete<String>(
          key: ValueKey(autoKey),
          initialValue: TextEditingValue(text: controller.text),

          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }

            return cachedCategories.where(
                  (option) => option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase())
            );
          },

          fieldViewBuilder: (
              context,
              textController,
              focusNode,
              onFieldSubmitted
              ) {
            // Sync with main controller
            textController.text = controller.text;
            textController.selection = TextSelection.fromPosition(
              TextPosition(offset: textController.text.length)
            );

            textController.addListener(() {
              if (controller.text != textController.text) {
                controller.text = textController.text;
              }
            });

            return TextField(
              controller: textController,
              focusNode: focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Groceries, Fuel',
                labelStyle: TextStyle(color: Colors.grey[500]),
                hintStyle: TextStyle(color: Colors.grey[700]),
                prefixIcon:
                const Icon(Icons.title, color: Color(0xFF64FFDA)),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF3C3C3C),
                    width: 1
                  )
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF64FFDA),
                    width: 2
                  )
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16
                )
              )
            );
          },

          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
                elevation: 8,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                    maxWidth: 300
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(color: Colors.white)
                          )
                        )
                      );
                    }
                  )
                )
              )
            );
          }
        );
      }
    );
});
  }


  // ❌ Delete Confirmation Dialog
  void _showDeleteConfirmation(BuildContext context, ExpenseItem expense) {
    final provider = context.read<ExpenseProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text(
              'Delete Expense?',
              style: TextStyle(color: Colors.white)
            )
          ]
        ),
        content: Text(
          'Are you sure you want to delete "${expense.title}"?',
          style: TextStyle(color: Colors.grey[400])
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[500])
            )
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteExpense(
                docId: expense.id,
                amount: expense.amount,
                type: expense.type,
                dateId: expense.dateId
              );

              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)
              )
            ),
            child: const Text('Delete')
          )
        ]
      )
    );
  }
}

class _ExpenseTypeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<ExpenseProvider, ExpenseType>(
      selector: (_, provider) => provider.selectedType,
      builder: (context, selectedType, _) {
        return Column(
          children: [
            _TypeButton(
              type: ExpenseType.saving,
              selected: selectedType == ExpenseType.saving
            ),
            const SizedBox(height: 12),
            _TypeButton(
              type: ExpenseType.needed,
              selected: selectedType == ExpenseType.needed
            ),
            const SizedBox(height: 12),
            _TypeButton(
              type: ExpenseType.luxury,
              selected: selectedType == ExpenseType.luxury
            )
          ]
        );
      }
    );
  }
}
class _TransactionTypeChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<ExpenseProvider, TransactionTypeEnum>(
      selector: (_, p) => p.selectedTransaction,
      builder: (_, selected, __) {
        return Wrap(
          spacing: 8,
          children: TransactionTypeEnum.values.map((type) {
            final isSelected = selected == type;

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 18,
                    color: isSelected ? Colors.black : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(type.label),
                ],
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF64FFDA),
              backgroundColor: const Color(0xFF2C2C2C),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                context.read<ExpenseProvider>().setTransactionType(type);
              },
            );
          }).toList(),
        );
      },
    );
  }
}


class _TypeButton extends StatelessWidget {
  final ExpenseType type;
  final bool selected;

  const _TypeButton({
    required this.type,
    required this.selected
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ExpenseProvider>();

    return GestureDetector(
      onTap: () => provider.setExpenseType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? type.color.withOpacity(0.2) : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? type.color : const Color(0xFF3C3C3C),
            width: selected ? 2 : 1
          )
        ),
        child: Column(
          children: [
            Icon(
              type.icon,
              color: selected ? type.color : Colors.grey[500],
              size: 26
            ),
            const SizedBox(height: 4),
            Text(
              type.label,
              style: TextStyle(
                color: selected ? type.color : Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w600
              )
            )
          ]
        )
      )
    );
  }
}
