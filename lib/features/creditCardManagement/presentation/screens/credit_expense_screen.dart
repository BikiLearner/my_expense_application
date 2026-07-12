import 'package:expence_app/features/expense/presentation/screens/expense_particular_day_overView.dart';
import 'package:expence_app/features/expense/presentation/widgets/add_expense_form.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../../expense/data/model/expense_items.dart';
import '../../../expense/presentation/provider/expence_provider.dart';
import '../../../expense/presentation/widgets/expense_tiles_new.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../provider/credit_expense_provider.dart';

class CreditExpenseScreen extends StatelessWidget {
  const CreditExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedDate = context.select<ExpenseProvider, DateTime>(
      (p) => p.selectedDate,
    );

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.payment_rounded, color: AppColor.creditPrimary),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd MMM yyyy').format(selectedDate),
              style: TextStyle(
                color: AppColor.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.credit_card_rounded,
              color: AppColor.creditPrimary,
            ),
            tooltip: 'Credit History',
            onPressed: () async {
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistoryScreen(),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: AppColor.textSecondary,
            ),
            tooltip: 'Select Date',
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: isDesktop
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
    );
  }


  Future<void> _selectDate(BuildContext context) async {
    final provider = context.read<CreditExpenseProvider>();

    final card = provider.selectedCreditCard;
    if (card == null) return;

    final cycle = card.billingCycle;

    bool isSelectable(DateTime date) {
      final inCurrent =
          !date.isBefore(cycle.currentStart) &&
              !date.isAfter(cycle.currentEnd);

      final inPrevious =
          !date.isBefore(cycle.previousStart) &&
              !date.isAfter(cycle.previousEnd);

      return inCurrent || inPrevious;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: cycle.previousStart,
      lastDate: cycle.currentEnd,
      selectableDayPredicate: isSelectable,
    );

    if (picked != null) {
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
        AddExpenseForm(isDesktop: false),
      ],
    );
  }

  // 🖥️ Desktop Layout (Side by Side)
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left: Expense List
        Expanded(flex: 3, child: _buildExpenseList(context)),
        // Right: Input Form
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: AppColor.surface,
            border: Border(
              left: BorderSide(color: AppColor.background, width: 1),
            ),
          ),
          child: AddExpenseForm(isDesktop: true),
        ),
      ],
    );
  }

  // 📋 Expense List Widget
  Widget _buildExpenseList(BuildContext context) {
    return Selector<ExpenseProvider, bool>(
      selector: (_, p) => p.isLoading,
      builder: (_, isLoading, __) {
        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColor.primary),
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
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses yet',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first expense below',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
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
                        gradient: LinearGradient(
                          colors: [AppColor.surface, AppColor.background],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ExpensesOverviewPageParticularDay(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${expenses.length} Transactions',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expense List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: expenses.length,
                        itemBuilder: (_, i) {
                          final expense = expenses[i];

                          return ExpenseItemTile(
                            expenseItem: expense,
                            toShow: true,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
