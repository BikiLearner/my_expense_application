import 'dart:ui';

import 'package:expence_app/enums/expense_type.dart';
import 'package:expence_app/history_screens/expense_type_breakdown_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expence_provider.dart';
import 'income_breakdown.dart';
import 'monthly_expense_page.dart';


class GrandTotalBanner extends StatelessWidget {
  final double grandTotal;
  final double yearExpense;
  final double yearIncome;
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
    required this.yearIncome,
    required this.totalDays,
    required this.onRefresh, required this.monthTotal, required this.saving, required this.luxury, required this.needed
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final savings = yearIncome - yearExpense;
    final moneyLeft = yearIncome - yearExpense;
    final monthKey =
        '${provider.selectedYear}-${provider.selectedMonth.toString().padLeft(2, '0')}';
    final label =
    DateFormat('MMMM yyyy').format(DateTime.parse("$monthKey-01"));
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF2A5298), Color(0xFF1E3A5F)]
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5)
          )
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _openYearPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2)
                    )
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF64FFDA),
                        size: 18
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.selectedYear,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold
                        )
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white
                      )
                    ]
                  )
                )
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onRefresh,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 24
                      )
                    )
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white
                      )
                    ),
                    color: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    offset: const Offset(0, 50),
                    onSelected: (value) {
                      if (value == 'savings') {
                        _showSavingsDialog(
                          context,
                          yearIncome,
                          yearExpense,
                          savings
                        );
                      } else if (value == 'income') {
                        _showAddIncomeDialog(context);
                      } else if (value == 'view_income') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IncomeBreakdownScreen(
                              year: provider.selectedYear
                            )
                          )
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view_income',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.blueAccent,
                                size: 20
                              )
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'View Income Breakdown',
                              style: TextStyle(color: Colors.white)
                            )
                          ]
                        )
                      ),
                      PopupMenuItem(
                        value: 'income',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF64FFDA).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFF64FFDA),
                                size: 20
                              )
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Add Income',
                              style: TextStyle(color: Colors.white)
                            )
                          ]
                        )
                      ),
                      PopupMenuItem(
                        value: 'savings',
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(
                                Icons.savings_outlined,
                                color: Colors.greenAccent,
                                size: 20
                              )
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'View Total Savings',
                              style: TextStyle(color: Colors.white)
                            )
                          ]
                        )
                      )
                    ]
                  )
                ]
              )
            ]
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
                      letterSpacing: 1
                    )
                  )
                ]
              ),
              const SizedBox(height: 8),
              Text(
                "₹${monthTotal.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1
                )
              ),
              const SizedBox(height: 6),
              Text(
                "${provider.selectedYear} expenses : ₹${grandTotal.toStringAsFixed(0)}",
                style: TextStyle(
                  color: const Color(0xFF64FFDA),
                  fontSize: 16,
                  fontWeight: FontWeight.w600
                )
              ),
              const SizedBox(height: 6),
              // Text(
              //     "This Month total income : ₹${grandTotal.toStringAsFixed(0)}",
              //     style: TextStyle(
              //         color: const Color(0xFF64FFDA),
              //         fontSize: 16,
              //         fontWeight: FontWeight.w600
              //     )
              // )

            ]
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.trending_down,
                  label: "Expenses",
                  value: "₹${yearExpense.toStringAsFixed(0)}",
                  color: Colors.redAccent, onTap: () {
}
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2)
                ),
                _StatItem(
                  icon: moneyLeft >= 0 ? Icons.account_balance_wallet : Icons.warning,
                  label: "Money Left",
                  value: "₹${moneyLeft.toStringAsFixed(0)}",
                  color: moneyLeft >= 0 ? Colors.greenAccent : Colors.redAccent, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>IncomeBreakdownScreen(year: provider.selectedYear)));
}
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2)
                ),
                _StatItem(
                  icon: Icons.calendar_today,
                  label: "Days",
                  value: "$totalDays",
                  color: const Color(0xFF64FFDA), onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>MonthlyExpensePage(label: label, monthKey: monthKey,)));
}
                )
              ]
            )
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.savings_outlined,
                  label: "Saving",
                  value:"₹${saving.toStringAsFixed(0)}" ,
                  extraWidget: _QuickStatCard(
                    icon: Icons.trending_up, label: 'Avg = ', value: (saving/totalDays).toStringAsFixed(0), color: Colors.greenAccent,

                  ),
                  color: Colors.greenAccent, onTap: () { 
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ExpenseTypeBreakdownScreen(type: ExpenseType.saving, monthKey:monthKey)));
                }
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2)
                ),
                _StatItem(
                  icon: Icons.auto_awesome_outlined,
                  label: "Luxury",
                  value: "₹${luxury.toStringAsFixed(0)}",
                    extraWidget: _QuickStatCard(
                      icon: Icons.trending_up, label: 'Avg = ', value: (luxury/totalDays).toStringAsFixed(0), color: Colors.pinkAccent,

                    ),
                  color: Colors.pinkAccent, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ExpenseTypeBreakdownScreen(type: ExpenseType.luxury, monthKey: monthKey,)));
                }
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2)
                ),
                _StatItem(
                  icon: Icons.shopping_cart_outlined,
                  label: "Needed",
                  value: "₹${needed.toStringAsFixed(0)}",
                    extraWidget: _QuickStatCard(
                      icon: Icons.trending_up, label: 'Avg = ', value: (needed/totalDays).toStringAsFixed(0), color: Colors.orangeAccent,

                    ),
                  color: Colors.orangeAccent, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>ExpenseTypeBreakdownScreen(type: ExpenseType.needed, monthKey: monthKey,)));
                }
                )
              ]
            )
          )

        ]
      )
    );
  }


  void _showAddIncomeDialog(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final amountController = TextEditingController();
    final sourceController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF64FFDA).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Icon(
                Icons.attach_money,
                color: Color(0xFF64FFDA)
              )
            ),
            const SizedBox(width: 12),
            const Text(
              "Add Income",
              style: TextStyle(color: Colors.white)
            )
          ]
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Amount",
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(
                  Icons.currency_rupee,
                  color: Color(0xFF64FFDA)
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                )
              )
            ),
            const SizedBox(height: 16),
            TextField(
              controller: sourceController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Source (Salary, Freelance, etc)",
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(
                  Icons.label_outline,
                  color: Color(0xFF64FFDA)
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                )
              )
            )
          ]
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[400])
            )
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12
              )
            ),
            onPressed: () async {
              final amount =
                  double.tryParse(amountController.text.trim()) ?? 0;

              if (amount > 0) {
                await provider.addIncome(
                  amount: amount,
                  source: sourceController.text.trim()
                );
                onRefresh();
              }

              Navigator.pop(context);
            },
            child: const Text(
              "Add",
              style: TextStyle(fontWeight: FontWeight.bold)
            )
          )
        ]
      )
    );
  }

  void _openYearPicker(BuildContext context) {
    final provider = context.read<ExpenseProvider>();
    final currentYear = DateTime.now().year;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (_) {
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
                  borderRadius: BorderRadius.circular(2)
                )
              ),
              const SizedBox(height: 16),
              const Text(
                "Select Year",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                )
              ),
              const SizedBox(height: 16),
              ...List.generate(6, (i) {
                final year = (currentYear - i).toString();
                final isSelected = year == provider.selectedYear;
                return ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color: isSelected
                        ? const Color(0xFF64FFDA)
                        : Colors.grey[600]
                  ),
                  title: Text(
                    year,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF64FFDA) : Colors.white,
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal
                    )
                  ),
                  trailing: isSelected
                      ? const Icon(
                    Icons.check_circle,
                    color: Color(0xFF64FFDA)
                  )
                      : null,
                  onTap: () {
                    provider.setYear(year);
                    Navigator.pop(context);
                    onRefresh();
                  }
                );
              })
            ]
          )
        );
      }
    );
  }

  void _showSavingsDialog(
      BuildContext context,
      double income,
      double expense,
      double savings
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: Colors.greenAccent
              )
            ),
            const SizedBox(width: 12),
            const Text(
              "Year Summary",
              style: TextStyle(color: Colors.white)
            )
          ]
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(
              icon: Icons.trending_up,
              label: "Income",
              value: income,
              color: Colors.greenAccent
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              icon: Icons.trending_down,
              label: "Expense",
              value: expense,
              color: Colors.redAccent
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),
            _SummaryRow(
              icon: Icons.savings,
              label: "Savings",
              value: savings,
              color: const Color(0xFF64FFDA),
              highlight: true
            )
          ]
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12
              )
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close",
              style: TextStyle(fontWeight: FontWeight.bold)
            )
          )
        ]
      )
    );
  }
}
class _TypeStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;

  const _TypeStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(icon, color: color, size: 22)
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12
          )
        ),
        const SizedBox(height: 4),
        Text(
          "₹${value.toStringAsFixed(0)}",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14
          )
        )
      ]
    );
  }
}


class _StatItem extends StatelessWidget {
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
    required this.color, required this.onTap, this.extraWidget
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11
            )
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold
            )
          ),
          if(extraWidget!=null) ...[extraWidget!]
        ]
      )
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final bool highlight;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? color.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8)
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: highlight ? color : Colors.grey[400],
              fontSize: 14
            )
          ),
          const Spacer(),
          Text(
            "₹${value.toStringAsFixed(0)}",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: highlight ? 18 : 16
            )
          )
        ]
      )
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
  Widget build(BuildContext context) {
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

