import 'dart:ui';

import 'package:expence_app/core/constants/date_constant.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../shared/enums/expense_type.dart';
import '../../data/model/credit_card.dart';
import '../../data/model/credit_card_expense_item_model.dart';
import '../provider/credit_expense_provider.dart';
import '../widgets/credit_expense_item_tile.dart'; // adjust path if different

class CreditExpensesOverviewPage extends StatelessWidget {
  const CreditExpensesOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.creditSurface,
      appBar: AppBar(
        backgroundColor: AppColor.creditDark,
        elevation: 0,
        foregroundColor: AppColor.textPrimary,
        title: Selector<CreditExpenseProvider, DateTime>(
          selector: (_, p) => p.selectedDate,
          builder: (context, date, _) {
            return Text(
              DateConstants.ddMMMyyyy(date),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            );
          },
        ),
        centerTitle: true,
      ),
      body: Selector<CreditExpenseProvider, bool>(
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
                return const _EmptyState();
              }

              final totals = _calculateTotals(expenses);

              return Selector<CreditExpenseProvider, CreditCardModel?>(
                selector: (_, p) => p.selectedCreditCard,
                builder: (_, card, __) {
                  final provider = context.read<CreditExpenseProvider>();
                  final used = card != null
                      ? provider.usedAmountForCard(card.creditCardId)
                      : 0.0;
                  final limit = card?.creditLimit ?? 0.0;
                  final left = (limit - used).clamp(0, limit);
                  final usageRatio = limit > 0
                      ? (used / limit).clamp(0.0, 1.0)
                      : 0.0;
                  final palette = card != null
                      ? AppColor.paletteFor(card.creditCardId)
                      : null;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // 🔝 CARD DETAILS BANNER — scrolls with everything else
                      if (card != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: _CardDetailsBanner(
                              card: card,
                              used: used,
                              left: left.toDouble(),
                              usageRatio: usageRatio,
                              palette: palette,
                            ),
                          ),
                        ),

                      // 🧮 TYPE SUMMARY SECTION
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                        child: Divider(height: 1, color: AppColor.creditBorder),
                      ),

                      // 📜 EXPENSE LIST (same scroll as banner + summary)
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final expense = expenses[i];
                            return CreditExpenseItemTile(
                              expenseItem: expense,
                              toShow: true,
                            );
                          }, childCount: expenses.length),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 🧮 Totals by type
  Map<ExpenseType, double> _calculateTotals(List<CreditExpenseItem> expenses) {
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

class _CardDetailsBanner extends StatelessWidget {
  final CreditCardModel card; // Ensure your model is imported
  final double used;
  final double left;
  final double usageRatio;
  final CreditCardPalette? palette;

  const _CardDetailsBanner({
    required this.card,
    required this.used,
    required this.left,
    required this.usageRatio,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final accent = palette?.accent ?? AppColor.creditAccent;

    final List<Color> glassGradient = palette != null
        ? palette!.gradient.map((c) => c.withOpacity(0.4)).toList()
        : [
            AppColor.creditGradientStart.withOpacity(0.4),
            AppColor.creditGradientEnd.withOpacity(0.2),
          ];

    return Container(
      width: double.infinity,
      // Outer shadow to give the glass card depth floating above the background
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.black.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      // ClipRRect is crucial so the BackdropFilter doesn't bleed outside the rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: glassGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              // Frosted glass border (light reflection on the edges)
              border: Border.all(
                color: AppColor.white.withOpacity(0.15),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Icon Container with inner glass feel
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: accent.withOpacity(0.35),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            Icons.credit_card_rounded,
                            size: 16,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${card.cardName} • ${card.bankName}',
                          style: const TextStyle(
                            color: AppColor.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Text(
                      'Limit ₹${card.creditLimit.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColor.textSecondary.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar Container
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: usageRatio,
                    minHeight: 6,
                    // Slightly more transparent background for the glass theme
                    backgroundColor: AppColor.white.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usageRatio >= 0.85
                          ? AppColor.creditDue
                          : usageRatio >= 0.6
                          ? AppColor.creditEMI
                          : AppColor.creditPaid,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Details Text
                Text(
                  '₹${left.toStringAsFixed(0)} left of ₹${card.creditLimit.toStringAsFixed(0)} • Used ₹${used.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: AppColor.textSecondary.withOpacity(0.8),
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeSummaryCard extends StatelessWidget {
  final ExpenseType type;
  final double amount;

  const _TypeSummaryCard({required this.type, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [type.color.withOpacity(0.35), type.color.withOpacity(0.15)],
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
              color: AppColor.textPrimary,
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
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColor.creditBorder,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: TextStyle(
              color: AppColor.creditLight,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adding some expenses',
            style: TextStyle(
              color: AppColor.creditLight.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
