import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'history_screens/month_list_page.dart';
import 'providers/expence_provider.dart';
import 'providers/history_page_provider.dart';

import 'history_screens/grand_total_banner.dart';
import 'history_screens/history_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late HistoryPageProvider _historyProvider;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  void _initializeProvider() {
    final expenseProvider = context.read<ExpenseProvider>();

    _historyProvider = HistoryPageProvider(
      uid: expenseProvider.uid,
      selectedYear: expenseProvider.selectedYear,
      selectedMonth: expenseProvider.selectedMonth,
    );

    // Fetch data
    _historyProvider.fetchHistoryData();
  }

  void _refresh() {
    // Recreate provider with current year/month
    _initializeProvider();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HistoryPageProvider>.value(
      value: _historyProvider,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: HistoryAppBar(),
        body: Consumer<HistoryPageProvider>(
          builder: (context, historyProvider, _) {
            // Handle loading state
            if (historyProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
              );
            }

            // Handle error state
            if (historyProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Error loading data",
                      style: TextStyle(color: Colors.red[400], fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      historyProvider.error!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            // Handle empty data
            if (historyProvider.yearExpenseDays.isEmpty) {
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

            final grouped = historyProvider.getGroupedByMonth();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  GrandTotalBanner(
                    grandTotal: historyProvider.yearExpense,
                    yearExpense: historyProvider.yearExpense,
                    totalDays: historyProvider.totalDays,
                    monthTotal: historyProvider.monthTotal,
                    saving: historyProvider.saving,
                    luxury: historyProvider.luxury,
                    needed: historyProvider.needed,
                    onRefresh: _refresh,
                  ),

                  _buildQuickStatsRow(
                    context,
                    historyProvider.avgPerDay,
                    historyProvider.highestDay,
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MonthlyExpensePageHolidingList(
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
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow(
      BuildContext context,
      double avgPerDay,
      double highestDay,
      ) {
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