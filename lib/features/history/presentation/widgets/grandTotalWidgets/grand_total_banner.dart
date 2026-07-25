import 'package:expence_app/core/constants/date_constant.dart';
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
import '../../../../../shared/widgets/custom_popup_menu.dart';
import '../../../../bank/presentation/provider/bank_provider.dart';
import '../../../../bank/presentation/screens/bank_list_page.dart';
import '../../../../expense/presentation/provider/expence_provider.dart';
import '../monthly_expense_page.dart';
import 'history_quick_stat_card.dart';
import 'history_stat_item.dart';
import 'month_selector.dart';

class GrandTotalBanner extends StatelessWidget {
  final double grandTotal;
  final double yearExpense;

  final int totalDays;
  final double monthTotal;
  final double saving;
  final double luxury;
  final double needed;

  final VoidCallback onRefresh;

  const GrandTotalBanner({
    super.key,
    required this.grandTotal,
    required this.yearExpense,

    required this.totalDays,
    required this.onRefresh,
    required this.monthTotal,
    required this.saving,
    required this.luxury,
    required this.needed,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final providerHistory = context.watch<HistoryPageProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420; // recommended breakpoint

    final monthKey =
        '${providerHistory.selectedYear}-${providerHistory.selectedMonth.toString().padLeft(2, '0')}';

    final label = DateFormat(
      'MMMM yyyy',
    ).format(DateTime.parse("$monthKey-01"));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColor.gradientStart,
            AppColor.gradientEnd,
            AppColor.gradientStart,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                          selectedYear: int.parse(provider.selectedYear),
                          onYearSelected: (int newYear) {
                            provider.setYear(
                              newYear.toString(),
                            );
                            onRefresh();
                          },
                        ),
                        const SizedBox(height: 8),
                        MonthSelector(
                          selectedMonth: provider.selectedMonth,
                          onMonthSelected: (int newMonth) {

                            provider.setMonth(newMonth);
                            onRefresh();
                          },
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        YearSelector(
                          selectedYear: int.parse(provider.selectedYear),
                          onYearSelected: (int newYear) {
                            provider.setYear(
                              newYear.toString(),
                            );
                            onRefresh();
                          },
                        ),
                        const SizedBox(width: 12),
                        MonthSelector(
                          selectedMonth: provider.selectedMonth,
                          onMonthSelected: (int newMonth) {

                            provider.setMonth(newMonth);
                            onRefresh();
                          },
                        ),
                      ],
                    ),

              Row(
                children: [
                  GestureDetector(
                    onTap: onRefresh,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
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
                        color: Colors.blueAccent,
                      ),
                      PopupActionItem(
                        value: 'bank_details',
                        title: 'Bank Details',
                        icon: Icons.currency_bitcoin,
                        color: Colors.greenAccent,
                      ),
                      PopupActionItem(
                        value: 'credit_card',
                        title: 'Credit cards',
                        icon: Icons.credit_card,
                        color: AppColor.creditAccent, // Or any color you prefer
                      ),
                    ],
                    // 2. Handle what happens when an item is tapped
                    onSelected: (String value) {
                      if (value == 'view_month_Bank_Details') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BankMonthlyBreakdownScreen(
                              year: provider.selectedYear,
                            ),
                          ),
                        );
                      } else if (value == 'bank_details') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BankPage()),
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
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${DateConstants.monthName(provider.selectedMonth)} • Expense",
                    style: TextStyle(
                      color: Colors.grey[300],
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
                      builder: (context) =>
                          MonthlyExpensePage(label: label, monthKey: monthKey),
                    ),
                  );
                },
                child: Text(
                  "₹${monthTotal.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "${provider.selectedYear} expenses : ₹${grandTotal.toStringAsFixed(0)}",
                style: TextStyle(
                  color: const Color(0xFF64FFDA),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                HistoryStatItem(
                  icon: Icons.trending_down,
                  label: "Expenses",
                  value: "₹${yearExpense.toStringAsFixed(0)}",
                  color: Colors.redAccent,
                  onTap: () {},
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Selector<BankProvider, double>(
                  selector: (_, provider) => provider.totalBankBalance,
                  builder: (_, total, __) {
                    return HistoryStatItem(
                      icon: total >= 0
                          ? Icons.account_balance_wallet
                          : Icons.warning,
                      label: "Money Left",
                      value: "₹${total.toStringAsFixed(0)}",
                      color: total >= 0 ? Colors.greenAccent : Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BankMonthlyBreakdownScreen(
                              year: provider.selectedYear,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                HistoryStatItem(
                  icon: Icons.calendar_today,
                  label: "Days",
                  value: "$totalDays",
                  color: const Color(0xFF64FFDA),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonthlyExpensePage(
                          label: label,
                          monthKey: monthKey,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                HistoryStatItem(
                  icon: Icons.savings_outlined,
                  label: "Saving",
                  value: "₹${saving.toStringAsFixed(0)}",
                  extraWidget: HistoryQuickStatCard(
                    icon: Icons.trending_up,
                    label: 'Avg = ',
                    value: (saving / totalDays).toStringAsFixed(0),
                    color: Colors.greenAccent,
                  ),
                  color: Colors.greenAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExpenseTypeBreakdownScreen(
                          type: ExpenseType.saving,
                          monthKey: monthKey,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                HistoryStatItem(
                  icon: Icons.auto_awesome_outlined,
                  label: "Luxury",
                  value: "₹${luxury.toStringAsFixed(0)}",
                  extraWidget: HistoryQuickStatCard(
                    icon: Icons.trending_up,
                    label: 'Avg = ',
                    value: (luxury / totalDays).toStringAsFixed(0),
                    color: Colors.pinkAccent,
                  ),
                  color: Colors.pinkAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExpenseTypeBreakdownScreen(
                          type: ExpenseType.luxury,
                          monthKey: monthKey,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                HistoryStatItem(
                  icon: Icons.shopping_cart_outlined,
                  label: "Needed",
                  value: "₹${needed.toStringAsFixed(0)}",
                  extraWidget: HistoryQuickStatCard(
                    icon: Icons.trending_up,
                    label: 'Avg = ',
                    value: (needed / totalDays).toStringAsFixed(0),
                    color: Colors.orangeAccent,
                  ),
                  color: Colors.orangeAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExpenseTypeBreakdownScreen(
                          type: ExpenseType.needed,
                          monthKey: monthKey,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
