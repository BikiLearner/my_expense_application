import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'enums/expense_type.dart';
import 'providers/expence_provider.dart';
import 'history_screen.dart';

class ExpenseScreen extends StatelessWidget
{
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) 
  {
    final selectedDate = context.select<ExpenseProvider, DateTime>(
      (p) => p.selectedDate
    );

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;
    final isMobile = screenWidth <= 600;

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
            onPressed: () =>
            context.read<ExpenseProvider>().selectDate(context)
          ),

          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF64FFDA)),
            tooltip: 'Add Title',
            onPressed: ()  {
              context.read<ExpenseProvider>().showAddCategoryDialog(context);

              // await context.read<ExpenseProvider>().migrateExpensesToYearMonthStats();
              //
              // if (context.mounted) {
              //   context.read<ExpenseProvider>(). showMigrationCompletedDialog(context);
              // }
              //
              // if (kDebugMode) {
              //   print("🎉 Migration completed — ALL expenses set to LUXURY");
              // }
            }
          ),
          const SizedBox(width: 8)
        ]
      ),
      body: isDesktop
        ? _buildDesktopLayout(context)
        : _buildMobileLayout(context)
    );
  }

  // 📱 Mobile & Tablet Layout (Stacked)
  Widget _buildMobileLayout(BuildContext context) 
  {
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
  Widget _buildDesktopLayout(BuildContext context) 
  {
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
  Widget _buildExpenseList(BuildContext context) 
  {
    return Consumer<ExpenseProvider>(
      builder: (_, provider, __) {
        return StreamBuilder(
          stream: provider.expenseStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) 
            {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF64FFDA)
                )
              );
            }

            if (snapshot.hasError) 
            {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                      size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading expenses',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16)
                    )
                  ]
                )
              );
            }

            if (!snapshot.hasData) 
            {
              return const Center(child: CircularProgressIndicator());
            }

            print(snapshot.data!.docs);
            final docs = snapshot.data!.docs;

            if (docs.isEmpty) 
            {
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)
                    )
                  ]
                )
              );
            }

            // Calculate total
            double total = 0;
            for (var doc in docs)
            {
              total += (doc['amount'] as num).toDouble();
            }

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
                              fontSize: 14,
                              fontWeight: FontWeight.w400
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
                          '${docs.length} items',
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
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final title = d['title'] ?? 'Untitled';
                      final description = d['description'] ?? '';
                      final amount = (d['amount'] as num).toDouble();
                      final expenseType = parseExpenseType(d['type']);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF2C2C2C),
                            width: 1
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2)
                            )
                          ]
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: expenseType.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Icon(
                              expenseType.icon,
                              color: expenseType.color,
                              size: 24
                            )
                          ),

                          title: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600
                            )
                          ),
                          subtitle: description.isNotEmpty
                            ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                description,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis
                              )
                            )
                            : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₹${amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFF64FFDA),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold
                                )
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.redAccent,
                                tooltip: 'Delete',
                                onPressed: () => _showDeleteConfirmation(
                                  context,
                                  provider,
                                  d.id,
                                  title,
                                  amount,
                                  expenseType,
                                  (d['createdAt'] as Timestamp).toDate(),
                                ),

                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                color: Colors.orangeAccent,
                                tooltip: 'Edit',
                                onPressed: () {
                                  final createdAt = (d['createdAt'] as Timestamp).toDate();

                                  _openEditExpense(
                                    context,
                                    provider,
                                    d.id,
                                    title,
                                    description,
                                    amount,
                                    d['type'],
                                    createdAt,
                                  );

                                }
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
  void _openEditExpense(
    BuildContext context,
    ExpenseProvider provider,
    String docId,
    String title,
    String description,
    double amount,
    String type,
    DateTime createdDate,
  ) {
    provider.titleController.text = title;
    provider.amountController.text = amount.toString();
    provider.descriptionController.text = description;

    final oldType = ExpenseType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => ExpenseType.needed,
    );

    provider.setExpenseType(oldType);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Edit Expense',
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: _buildInputForm(context, isDesktop: true),
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearForm();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.editExpense(
                docId: docId,
                oldAmount: amount,
                oldType: oldType,
                oldDate: createdDate,
              );
              Navigator.pop(context);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ✏️ Input Form Widget
  Widget _buildInputForm(BuildContext context, {required bool isDesktop}) 
  {
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
                        _buildTitleAutoComplete(
                          context,
                          provider.titleController,
                        ),

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
  }) 
  {
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
      TextEditingController controller,
      ) {
    final provider = context.read<ExpenseProvider>();

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }

        // 🔹 Replace with your real category source if needed
        final suggestions = provider.cachedCategories;

        return suggestions.where(
              (option) => option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase()),
        );
      },
      onSelected: (selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (
          context,
          textController,
          focusNode,
          onFieldSubmitted,
          ) {
        textController.text = controller.text;

        return TextField(
          controller: textController,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Title',
            hintText: 'e.g., Groceries, Fuel',
            labelStyle: TextStyle(color: Colors.grey[500]),
            hintStyle: TextStyle(color: Colors.grey[700]),
            prefixIcon: const Icon(Icons.title, color: Color(0xFF64FFDA)),
            filled: true,
            fillColor: const Color(0xFF2C2C2C),
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
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(12),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (_, index) {
                final option = options.elementAt(index);
                return ListTile(
                  title: Text(
                    option,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ❌ Delete Confirmation Dialog
  void _showDeleteConfirmation(
    BuildContext context,
    ExpenseProvider provider,
    String docId,
    String title,
    double amo,
    ExpenseType type,
    DateTime date,
  )

  {
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
          'Are you sure you want to delete "$title"?',
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
                docId: docId,
                amount: amo,
                type: type,
                date: date,
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

class _ExpenseTypeSelector extends StatelessWidget
{
  @override
  Widget build(BuildContext context) 
  {
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

class _TypeButton extends StatelessWidget
{
  final ExpenseType type;
  final bool selected;

  const _TypeButton({
    required this.type,
    required this.selected
  });

  @override
  Widget build(BuildContext context) 
  {
    final provider = context.read<ExpenseProvider>();

    return GestureDetector(
      onTap: () => provider.setExpenseType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
            ? type.color.withOpacity(0.2)
            : const Color(0xFF2C2C2C),
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

