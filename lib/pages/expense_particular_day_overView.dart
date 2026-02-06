import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expence_provider.dart';
import '../models/expense_items.dart';
import '../enums/expense_type.dart';
import '../reusable widgets/expense_tiles_new.dart';

class ExpensesOverviewPageParticularDay extends StatelessWidget {
  const ExpensesOverviewPageParticularDay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        foregroundColor: Colors.white, // ✅ FIX ICON + TEXT
        title: const Text(
          'All Transactions',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Selector<ExpenseProvider, bool>(
        selector: (_, p) => p.isLoading,
        builder: (_, isLoading, __) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF64FFDA),
              ),
            );
          }

          return Selector<ExpenseProvider, List<ExpenseItem>>(
            selector: (_, p) => p.cachedExpenses,
            builder: (_, expenses, __) {
              if (expenses.isEmpty) {
                return const _EmptyState();
              }

              final totals = _calculateTotals(expenses);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 🔝 SUMMARY SECTION
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Row(
                        children: ExpenseType.values.map((type) {
                          return Expanded(
                            child: _TypeSummaryCard(
                              type: type,
                              amount: totals[type] ?? 0.0,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // Divider
                  SliverToBoxAdapter(
                    child: Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),

                  // 📜 EXPENSE LIST (PART OF SAME SCROLL)
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, i) {
                          final expense = expenses[i];
                          return ExpenseItemTile(
                            expenseItem: expense,
                            toShow: true,
                          );
                        },
                        childCount: expenses.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 🧮 Totals by type
  Map<ExpenseType, double> _calculateTotals(List<ExpenseItem> expenses) {
    final Map<ExpenseType, double> totals = {
      ExpenseType.saving: 0.0,
      ExpenseType.needed: 0.0,
      ExpenseType.luxury: 0.0,
    };

    for (final e in expenses) {
      totals[e.type] = (totals[e.type] ?? 0) + e.amount;
    }

    return totals;
  }
}
class _TypeSummaryCard extends StatelessWidget {
  final ExpenseType type;
  final double amount;

  const _TypeSummaryCard({
    required this.type,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            type.color.withOpacity(0.35),
            type.color.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: type.color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, color: type.color, size: 28),
          const SizedBox(height: 8),
          Text(
            type.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: type.color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adding some expenses',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
