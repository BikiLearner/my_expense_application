import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/audio_player.dart';
import '../widgets/month_list_page.dart';
import '../../../expense/presentation/provider/expence_provider.dart';
import '../provider/history_page_provider.dart';

import '../widgets/grand_total_banner.dart';
import '../widgets/history_app_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expense = context.read<ExpenseProvider>();

    return ChangeNotifierProvider(
      create: (_) => HistoryPageProvider(
        uid: expense.uid,
        selectedYear: expense.selectedYear,
        selectedMonth: expense.selectedMonth,
      )..fetchHistoryData(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: HistoryAppBar(),
      body: Consumer<HistoryPageProvider>(
        builder: (context, history, _) {

          // 🔄 Loading
          if (history.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF64FFDA),
              ),
            );
          }

          // ❌ Error
          if (history.error != null) {
            return _ErrorView(
              message: history.error!,
              onRetry: history.fetchHistoryData,
            );
          }

          // 🟡 Empty
          if (history.yearExpenseDays.isEmpty) {
            return const _EmptyHistoryView();
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [

                /// 🔥 GRAND TOTAL BANNER
                GrandTotalBanner(
                  grandTotal: history.yearExpense,
                  yearExpense: history.yearExpense,
                  totalDays: history.totalDays,
                  monthTotal: history.monthTotal,
                  saving: history.saving,
                  luxury: history.luxury,
                  needed: history.needed,
                  onRefresh: history.fetchHistoryData,
                ),

                /// 📊 QUICK STATS
                _QuickStatsRow(
                  avg: history.avgPerDay,
                  highest: history.highestDay,
                ),

                /// 📅 GO TO MONTH LIST
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _MonthNavigationTile(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          const Text(
            "Error loading data",
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[600]),
          const SizedBox(height: 16),
          const Text(
            "No expenses yet",
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "Start tracking your expenses",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
class _QuickStatsRow extends StatelessWidget {
  final double avg;
  final double highest;

  const _QuickStatsRow({
    required this.avg,
    required this.highest,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickStatCard(
              icon: Icons.trending_up,
              label: "Avg",
              value: "₹${avg.toStringAsFixed(0)}",
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.arrow_upward,
              label: "Highest",
              value: "₹${highest.toStringAsFixed(0)}",
              color: Colors.orangeAccent,
            ),
          ),
        ],
      ),
    );
  }
}
class _MonthNavigationTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final audioService = AudioPlayerService();
          await audioService.play('audio/fahhhhh.mp3', isAsset: true);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MonthlyExpensePageHolidingList(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: const [
              Icon(Icons.calendar_month, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Go to monthly expenses",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
            ],
          ),
        ),
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