import 'dart:ui';

import 'package:expence_app/enums/expense_type.dart';
import 'package:expence_app/history_screens/bank_monthly_break_down_screen.dart';
import 'package:expence_app/history_screens/expense_type_breakdown_screen.dart';
import 'package:expence_app/providers/history_page_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../pages/bank_list_page.dart';
import '../providers/bank_provider.dart';
import '../providers/expence_provider.dart';
import 'monthly_expense_page.dart';

class GrandTotalBanner extends StatelessWidget
{
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
  Widget build(BuildContext context) 
  {
    final provider = context.watch<ExpenseProvider>();
    final providerHistory = context.watch<HistoryPageProvider>();

    final monthKey =
      '${provider.selectedYear}-${provider.selectedMonth.toString().padLeft(2, '0')}';
    final label = DateFormat(
      'MMMM yyyy',
    ).format(DateTime.parse("$monthKey-01"));
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2A5298), Color(0xFF1E3A5F)],
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
              Row(
                children: [
                  _YearSelector(
                    year: providerHistory.selectedYear,
                    onTap: () => _openYearPicker(context),
                  ),
                  const SizedBox(width: 12),
                  _MonthSelector(
                    month: providerHistory.selectedMonth,
                    onTap: () => _openMonthPicker(context),
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
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                    color: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    offset: const Offset(0, 50),
                    onSelected: (value)
                    {
                      if (value == 'view_month_Bank_Details') 
                      {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BankMonthlyBreakdownScreen(
                              year: provider.selectedYear,
                            ),
                          ),
                        );
                      }
                      else if (value == 'bank_details') 
                      {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BankPage(
                            ),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view_month_Bank_Details',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.blueAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'View Month Bank Breakdown',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'bank_details',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.currency_bitcoin,
                                color: Colors.greenAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Bank Details',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                    "${provider.monthFromInt(provider.selectedMonth)} • Expense",
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "₹${monthTotal.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
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
                _StatItem(
                  icon: Icons.trending_down,
                  label: "Expenses",
                  value: "₹${yearExpense.toStringAsFixed(0)}",
                  color: Colors.redAccent,
                  onTap: ()
                  {
                  },
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Selector<BankProvider, double>(
                  selector: (_, provider) => provider.totalBankBalance,
                  builder: (_, total, __)
                  {
                    return
                    _StatItem(
                      icon: total >= 0
                        ? Icons.account_balance_wallet
                        : Icons.warning,
                      label: "Money Left",
                      value: "₹${total.toStringAsFixed(0)}",
                      color: total >= 0 ? Colors.greenAccent : Colors.redAccent,
                      onTap: ()
                      {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            BankMonthlyBreakdownScreen(year: provider.selectedYear),
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
                _StatItem(
                  icon: Icons.calendar_today,
                  label: "Days",
                  value: "$totalDays",
                  color: const Color(0xFF64FFDA),
                  onTap: ()
                  {
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
                _StatItem(
                  icon: Icons.savings_outlined,
                  label: "Saving",
                  value: "₹${saving.toStringAsFixed(0)}",
                  extraWidget: _QuickStatCard(
                    icon: Icons.trending_up,
                    label: 'Avg = ',
                    value: (saving / totalDays).toStringAsFixed(0),
                    color: Colors.greenAccent,
                  ),
                  color: Colors.greenAccent,
                  onTap: ()
                  {
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
                _StatItem(
                  icon: Icons.auto_awesome_outlined,
                  label: "Luxury",
                  value: "₹${luxury.toStringAsFixed(0)}",
                  extraWidget: _QuickStatCard(
                    icon: Icons.trending_up,
                    label: 'Avg = ',
                    value: (luxury / totalDays).toStringAsFixed(0),
                    color: Colors.pinkAccent,
                  ),
                  color: Colors.pinkAccent,
                  onTap: ()
                  {
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
                _StatItem(
                  icon: Icons.shopping_cart_outlined,
                  label: "Needed",
                  value: "₹${needed.toStringAsFixed(0)}",
                  extraWidget: _QuickStatCard(
                    icon: Icons.trending_up,
                    label: 'Avg = ',
                    value: (needed / totalDays).toStringAsFixed(0),
                    color: Colors.orangeAccent,
                  ),
                  color: Colors.orangeAccent,
                  onTap: ()
                  {
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


  void _openYearPicker(BuildContext context) {
    final provider = context.read<HistoryPageProvider>();
    final currentYear = DateTime.now().year;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_)
      {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Select Year",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...List.generate(6, (i)
                {
                  final year = (currentYear - i).toString();
                  final isSelected = year == provider.selectedYear;
                  return ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: isSelected
                        ? const Color(0xFF64FFDA)
                        : Colors.grey[600],
                    ),
                    title: Text(
                      year,
                      style: TextStyle(
                        color: isSelected
                          ? const Color(0xFF64FFDA)
                          : Colors.white,
                        fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Color(0xFF64FFDA))
                      : null,
                    onTap: ()
                    {
                      provider.setYear(year);
                      Navigator.pop(context);
                      onRefresh();
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }
  void _openMonthPicker(BuildContext context) {
    final provider = context.read<HistoryPageProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: 12,
          itemBuilder: (_, i) {
            final month = i + 1;
            final label = DateFormat.MMMM().format(DateTime(0, month));
            final isSelected = provider.selectedMonth == month;

            return ListTile(
              leading: Icon(
                Icons.calendar_month,
                color: isSelected
                    ? const Color(0xFF64FFDA)
                    : Colors.grey,
              ),
              title: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF64FFDA)
                      : Colors.white,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF64FFDA))
                  : null,
              onTap: () {
                provider.setMonth(month);
                Navigator.pop(context);
                onRefresh(); // 🔥 THIS triggers history reload
              },
            );
          },
        );
      },
    );
  }


}
class _YearSelector extends StatelessWidget {
  final String year;
  final VoidCallback onTap;

  const _YearSelector({
    required this.year,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF64FFDA),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              year,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final int month;
  final VoidCallback onTap;

  const _MonthSelector({
    required this.month,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.MMM().format(DateTime(0, month));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month,
                color: Color(0xFF64FFDA), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}


class _StatItem extends StatelessWidget
{
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Function() onTap;
  final Widget? extraWidget;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) 
  {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (extraWidget != null) ...[extraWidget!],
        ],
      ),
    );
  }
}


class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) 
  {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$label $value',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
