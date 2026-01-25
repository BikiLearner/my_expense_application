import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'history_screens/month_list_page.dart';
import 'models/month_stats.dart';
import 'models/year_stats.dart';
import 'providers/expence_provider.dart';
import 'expense_model.dart';

import 'history_screens/grand_total_banner.dart';
import 'history_screens/history_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _refreshKey = 0;

  void _refresh() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: HistoryAppBar(),
      body: FutureBuilder<List<ExpenseDay>>(
        key: ValueKey(_refreshKey),
        future: provider.getAllExpenseDays(),
        builder: (context, expenseSnapshot) {
          if (expenseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            );
          }

          if (!expenseSnapshot.hasData || expenseSnapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No expenses yet",
                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Start tracking your expenses\nto see insights here",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final days = expenseSnapshot.data!;
          days.sort((a, b) => b.dateId.compareTo(a.dateId));

          final grouped = _groupByMonth(days);

          return FutureBuilder(
            future: Future.wait([
              provider.getYearStats(),
              provider.getMonthStatsByMonth(
                DateTime.now().toString().substring(
                  0,
                  7,
                ), // yyyy-MM (current month)
              ),
              provider.getYearIncomeFromFirestore(provider.selectedYear),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
                );
              }

              final yearStats = snapshot.data![0] as YearStats?;
              final monthStats = snapshot.data![1] as MonthStats?;
              final yearIncome = snapshot.data![2] as double;

              final yearExpense = yearStats?.grandTotal ?? 0.0;

              final yearDays = days
                  .where((d) => d.dateId.startsWith(provider.selectedYear))
                  .length;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    GrandTotalBanner(
                      grandTotal: yearExpense,
                      yearExpense: yearExpense,
                      yearIncome: yearIncome,
                      totalDays: yearDays,

                      // 🔥 NEW (FROM MONTH STATS)
                      monthTotal: monthStats?.grandTotal ?? 0,
                      saving: monthStats?.saving ?? 0,
                      luxury: monthStats?.luxury ?? 0,
                      needed: monthStats?.needed ?? 0,

                      onRefresh: _refresh,
                    ),

                    _buildQuickStatsRow(context, days, yearExpense, yearDays),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Material(
                          color: Colors.transparent, // important for ripple
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MonthlyExpensePageHolidingList(
                                        grouped: grouped,
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Leading icon
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  const Expanded(
                                    child: Text(
                                      'Go to monthly expenses',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),

                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 🔥 NEW: Quick Stats Row
  Widget _buildQuickStatsRow(
    BuildContext context,
    List<ExpenseDay> days,
    double yearExpense,
    int yearDays,
  ) {
    final provider = context.read<ExpenseProvider>();
    final yearDays2 = days
        .where((d) => d.dateId.startsWith(provider.selectedYear))
        .toList();

    // Calculate average per day
    final avgPerDay = yearDays > 0 ? yearExpense / yearDays : 0;

    // Calculate highest spending day
    double highestDay = 0;
    if (yearDays2.isNotEmpty) {
      highestDay = yearDays2
          .map((d) => d.total)
          .reduce((a, b) => a > b ? a : b);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _QuickStatCard(
              icon: Icons.trending_up,
              label: "Avg",
              value: "₹${avgPerDay.toStringAsFixed(0)}",
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.arrow_upward,
              label: "Highest",
              value: "₹${highestDay.toStringAsFixed(0)}",
              color: Colors.orangeAccent,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<ExpenseDay>> _groupByMonth(List<ExpenseDay> days) {
    final Map<String, List<ExpenseDay>> map = {};
    for (final d in days) {
      final key = d.dateId.substring(0, 7);
      map.putIfAbsent(key, () => []).add(d);
    }
    return map;
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
