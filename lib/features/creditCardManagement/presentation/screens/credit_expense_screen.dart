import 'package:expence_app/features/creditCardManagement/data/model/credit_card_expense_item_model.dart';
import 'package:expence_app/features/creditCardManagement/presentation/widgets/credit_expense_item_tile.dart';
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
import '../widgets/add_credit_expense_form.dart';

class CreditExpenseScreen extends StatelessWidget {
  const CreditExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedDate = context.select<CreditExpenseProvider, DateTime>(
          (p) => p.selectedDate,
    );

    // Responsive breakpoints
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      backgroundColor: AppColor.creditDark,
      appBar: AppBar(
        backgroundColor: AppColor.creditSurface,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.payment_rounded, color: AppColor.creditAccent),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd MMM yyyy').format(selectedDate),
              style: const TextStyle(
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
              color: AppColor.creditAccent,
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

    if (provider.selectedBillingCycleModel == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: provider.minimumSelectableDate,
      lastDate: provider.maximumSelectableDate,
      selectableDayPredicate: provider.isDateInCurrentBillingCycle,
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
        const AddCreditExpenseForm(isDesktop: false),
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
          decoration: const BoxDecoration(
            color: AppColor.creditSurface,
            border: Border(
              left: BorderSide(color: AppColor.creditDark, width: 1),
            ),
          ),
          child: const AddCreditExpenseForm(isDesktop: true),
        ),
      ],
    );
  }

  // 📋 Expense List Widget
  Widget _buildExpenseList(BuildContext context) {
    return Selector<CreditExpenseProvider, bool>(
      selector: (_, p) => p.isLoading,
      builder: (_, isLoading, __) {
        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColor.creditAccent),
          );
        }

        return Selector<CreditExpenseProvider, List<CreditExpenseItem>>(
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
                      color: AppColor.grey700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No expenses yet',
                      style: TextStyle(
                        color: AppColor.grey500,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add your first expense below',
                      style: TextStyle(color: AppColor.grey600, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return Selector<CreditExpenseProvider, double>(
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
                          colors: [
                            AppColor.creditGradientStart,
                            AppColor.creditGradientEnd
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.black.withOpacity(0.3),
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
                              const Text(
                                'Total Expenses',
                                style: TextStyle(
                                  color: AppColor.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColor.white,
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
                                  const ExpensesOverviewPageParticularDay(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColor.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${expenses.length} Transactions',
                                style: const TextStyle(
                                  color: AppColor.white,
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

                          return CreditExpenseItemTile(
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