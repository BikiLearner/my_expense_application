import 'package:expence_app/core/constants/date_constant.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:expence_app/features/creditCardManagement/presentation/screens/credit_card_screen.dart';
import 'package:expence_app/features/history/presentation/provider/history_page_provider.dart';
import 'package:expence_app/features/history/presentation/widgets/bank_monthly_break_down_screen.dart';
import 'package:expence_app/features/history/presentation/widgets/expense_type_breakdown_screen.dart';
import 'package:expence_app/features/history/presentation/widgets/grandTotalWidgets/year_selector.dart';
import 'package:expence_app/shared/enums/expense_type.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../core/theme/app_color.dart';
import '../../../../../shared/models/month_stats.dart';
import '../../../../../shared/models/year_stats.dart';
import '../../../../../shared/providers/home_navigation_provider.dart';
import '../../../../../shared/widgets/custom_popup_menu.dart';
import '../../../../bank/presentation/screens/bank_list_page.dart';
import '../monthly_expense_page.dart';
import 'history_quick_stat_card.dart';
import 'history_stat_item.dart';
import 'month_selector.dart';
import 'no_expense_for_month_widget.dart';

class GrandTotalCreditCardOne extends StatelessWidget {
  const GrandTotalCreditCardOne({super.key});

  @override
  Widget build(BuildContext context) {
    final providerHistory = context.read<HistoryPageProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420; // recommended breakpoint

    final monthKey =
        '${providerHistory.selectedYear}-${providerHistory.selectedMonth.toString().padLeft(2, '0')}';

    final label = DateFormat(
      'MMMM yyyy',
    ).format(DateTime.parse("$monthKey-01"));

    return Selector<HistoryPageProvider, (YearStats?, MonthStats?, int)>(
      selector: (_, provider) => (
        provider.creditYearStats,
        provider.creditMonthStats,
        provider.totalDays,
      ),
      builder: (context, stats, child) {
        final YearStats? yearStats = stats.$1;
        final MonthStats? monthStats = stats.$2;
        final int totalDays = stats.$3;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColor.creditGradientStart,
                AppColor.creditPrimary,
                AppColor.creditGradientEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColor.creditBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColor.creditDark.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColor.creditAccent.withOpacity(0.04),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  isSmallScreen
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            YearSelector(
                              selectedYear: int.parse(
                                providerHistory.selectedYear,
                              ),
                              onYearSelected: (int newYear) {
                                providerHistory.setYear(newYear.toString());
                                providerHistory.refresh();
                              },
                            ),
                            const SizedBox(height: 8),
                            MonthSelector(
                              selectedMonth: providerHistory.selectedMonth,
                              onMonthSelected: (int newMonth) {
                                providerHistory.setMonth(newMonth);
                                providerHistory.refresh();
                              },
                            ),
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            YearSelector(
                              selectedYear: int.parse(
                                providerHistory.selectedYear,
                              ),
                              onYearSelected: (int newYear) {
                                providerHistory.setYear(newYear.toString());
                                providerHistory.refresh();
                              },
                            ),
                            const SizedBox(width: 12),
                            MonthSelector(
                              selectedMonth: providerHistory.selectedMonth,
                              onMonthSelected: (int newMonth) {
                                providerHistory.setMonth(newMonth);
                                providerHistory.refresh();
                              },
                            ),
                          ],
                        ),

                  Row(
                    children: [
                      GestureDetector(
                        onTap: context
                            .read<HomeNavigationProvider>()
                            .toggleScreen,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.creditAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColor.creditBorder,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.flip,
                            color: AppColor.creditAccent,

                            size: 24,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: providerHistory.refresh,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.creditAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColor.creditBorder,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: AppColor.creditLight,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomActionPopupMenu(
                        // 1. Define the items you want for THIS specific screen
                        items: const [
                          PopupActionItem(
                            value: 'view_month_Bank_Details',
                            title: 'View Month Bank Breakdown',
                            icon: Icons.receipt_long,
                            color: AppColor.creditLimit,
                          ),
                          PopupActionItem(
                            value: 'bank_details',
                            title: 'Bank Details',
                            icon: Icons.currency_bitcoin,
                            color: AppColor.creditPaid,
                          ),
                          PopupActionItem(
                            value: 'credit_card',
                            title: 'Credit cards',
                            icon: Icons.credit_card,
                            color: AppColor.creditAccent,
                          ),
                        ],
                        // 2. Handle what happens when an item is tapped
                        onSelected: (String value) {
                          if (value == 'view_month_Bank_Details') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BankMonthlyBreakdownScreen(
                                  year: providerHistory.selectedYear,
                                ),
                              ),
                            );
                          } else if (value == 'bank_details') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BankPage(),
                              ),
                            );
                          } else if (value == 'credit_card') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreditCardScreen(),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (monthStats == null)
                NoExpenseForMonth(
                  month: DateConstants.monthName(providerHistory.selectedMonth),
                  year: providerHistory.selectedYear,
                )
              else
                _buildHistoryStats(
                  context: context,
                  providerHistory: providerHistory,
                  monthStats: monthStats,
                  yearStats: yearStats!,
                  totalDays: totalDays,
                  monthKey: monthKey,
                  label: label,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryStats({
    required BuildContext context,
    required HistoryPageProvider providerHistory,
    required MonthStats monthStats,
    required YearStats yearStats,
    required int totalDays,
    required String monthKey,
    required String label,
  }) {
    return Column(
      children: [
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${DateConstants.monthName(providerHistory.selectedMonth)} • Expense",
                  style: TextStyle(
                    color: AppColor.creditLight.withOpacity(0.7),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MonthlyExpensePage(label: label, monthKey: monthKey),
                  ),
                );
              },
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColor.creditAccent, AppColor.creditLight],
                ).createShader(bounds),
                child: Text(
                  "₹${monthStats.grandTotal.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "${providerHistory.selectedYear} expenses : "
              "₹${yearStats.grandTotal.toStringAsFixed(0)}",
              style: const TextStyle(
                color: AppColor.creditAccent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),
          ],
        ),

        const SizedBox(height: 16),

        // ================= YEAR / BALANCE / DAYS =================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColor.creditDark.withOpacity(0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColor.creditBorder, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              HistoryStatItem(
                icon: Icons.trending_down,
                label: "Expenses",
                value: "₹${yearStats.grandTotal.toStringAsFixed(0)}",
                color: AppColor.creditDue,
                onTap: () {},
              ),

              _buildDivider(),

              Selector<CreditExpenseProvider, double>(
                selector: (_, provider) => provider.totalAvailableCredit,
                builder: (_, available, __) {
                  return HistoryStatItem(
                    icon: Icons.credit_card,
                    label: "Available Credit",
                    value: "₹${available.toStringAsFixed(0)}",
                    color: AppColor.creditPaid,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreditCardScreen(),
                        ),
                      );
                    },
                  );
                },
              ),

              _buildDivider(),

              Selector<CreditExpenseProvider, int>(
                selector: (_, provider) => provider.cardsUsedCount,
                builder: (_, cardUsed, __) {
                  return HistoryStatItem(
                    icon: Icons.calendar_today,
                    label: "Cards Used",
                    value: "$cardUsed",
                    color: AppColor.creditLimit,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreditCardScreen(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ================= EXPENSE TYPES =================
        Selector<HistoryPageProvider, (double?, double?, double)>(
          selector: (_, provider) => (
            provider.creditNeededPercent,
            provider.creditLuxuryPercent,
            provider.creditSavingPercent,
          ),
          builder: (context, stats, child) {
            final double creditNeededPercentage = stats.$1 ?? 0;
            final double creditLuxuryPercent = stats.$2 ?? 0;
            final double creditSavingPercent = stats.$3 ?? 0;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.creditDark.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColor.creditBorder, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  HistoryStatItem(
                    icon: Icons.savings_outlined,
                    label: "Saving",
                    value: "₹${monthStats.saving.toStringAsFixed(0)}",
                    extraWidget: HistoryQuickStatCard(
                      icon: Icons.trending_up,
                      label: 'Avg = ',
                      value: '${creditSavingPercent.toStringAsFixed(0)}%',
                      color: AppColor.creditPaid,
                    ),
                    color: AppColor.creditPaid,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpenseTypeBreakdownScreen(
                            type: ExpenseType.saving,
                            monthKey: monthKey,
                          ),
                        ),
                      );
                    },
                  ),

                  _buildDivider(),

                  HistoryStatItem(
                    icon: Icons.auto_awesome_outlined,
                    label: "Luxury",
                    value: "₹${monthStats.luxury.toStringAsFixed(0)}",
                    extraWidget: HistoryQuickStatCard(
                      icon: Icons.trending_up,
                      label: 'Avg = ',
                      value: '${creditLuxuryPercent.toStringAsFixed(0)}%',
                      color: AppColor.creditDue,
                    ),
                    color: AppColor.creditDue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpenseTypeBreakdownScreen(
                            type: ExpenseType.luxury,
                            monthKey: monthKey,
                          ),
                        ),
                      );
                    },
                  ),

                  _buildDivider(),

                  HistoryStatItem(
                    icon: Icons.shopping_cart_outlined,
                    label: "Needed",
                    value: "₹${monthStats.needed.toStringAsFixed(0)}",
                    extraWidget: HistoryQuickStatCard(
                      icon: Icons.trending_up,
                      label: 'Avg = ',
                      value: '${creditNeededPercentage.toStringAsFixed(0)}%',
                      color: AppColor.creditEMI,
                    ),
                    color: AppColor.creditEMI,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpenseTypeBreakdownScreen(
                            type: ExpenseType.needed,
                            monthKey: monthKey,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: AppColor.creditBorder);
  }
}
