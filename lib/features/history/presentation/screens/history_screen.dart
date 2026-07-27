import 'package:expence_app/shared/providers/home_navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/audio_player.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../shared/widgets/linked_flip_card.dart';
import '../provider/history_page_provider.dart';
import '../widgets/grandTotalWidgets/grand_total_banner.dart';
import '../widgets/grandTotalWidgets/grand_total_credit_card_one.dart';
import '../widgets/history_app_bar.dart';
import '../widgets/month_list_page.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<HistoryPageProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final showCredit = context.select<HomeNavigationProvider, bool>(
      (provider) => provider.showCredit,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: HistoryAppBar(),
      body: Consumer<HistoryPageProvider>(
        builder: (context, history, _) {
          // 🔄 Loading
          if (history.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
            );
          }

          // ❌ Error
          if (history.error != null) {
            return _ErrorView(
              message: history.error!,
              onRetry: history.fetchHistoryData,
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                /// 🔥 GRAND TOTAL BANNER
                LinkedFlipCard(
                  showBack: showCredit,
                  front: const GrandTotalBanner(),
                  back: const GrandTotalCreditCardOne(),
                ),

                /// 📊 QUICK STATS
                LinkedFlipCard(
                  showBack: showCredit,
                  front: _QuickStatsRow(
                    avg: history.avgPerDay,
                    highest: history.highestDay,
                  ),
                  back: _QuickStatsRow(
                    isCredit: true,
                    avg: history.avgPerDay,
                    highest: history.highestDay,
                  ),
                ),

                /// 📅 GO TO MONTH LIST
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: LinkedFlipCard(
                    showBack: showCredit,
                    front: _MonthNavigationTile(),
                    back: _MonthNavigationTile(isCredit: true),
                  ),
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

  const _ErrorView({required this.message, required this.onRetry});

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
          ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final double avg;
  final double highest;
  final bool isCredit;

  const _QuickStatsRow({
    required this.avg,
    required this.highest,
    this.isCredit = false,
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
              color: isCredit ? AppColor.creditLimit : Colors.blueAccent,
              isCredit: isCredit,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickStatCard(
              icon: Icons.arrow_upward,
              label: "Highest",
              value: "₹${highest.toStringAsFixed(0)}",
              color: isCredit ? AppColor.creditEMI : Colors.orangeAccent,
              isCredit: isCredit,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthNavigationTile extends StatelessWidget {
  final bool isCredit;

  const _MonthNavigationTile({this.isCredit = false});

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
            MaterialPageRoute(builder: (_) => MonthlyExpensePageHolidingList()),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isCredit
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColor.creditGradientStart,
                      AppColor.creditPrimary,
                    ],
                  )
                : null,
            color: isCredit ? null : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: isCredit
                ? Border.all(color: AppColor.creditBorder, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: isCredit ? AppColor.creditAccent : Colors.green,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Go to monthly expenses",
                  style: TextStyle(
                    color: isCredit ? AppColor.creditLight : Colors.white,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isCredit
                    ? AppColor.creditLight.withOpacity(0.7)
                    : Colors.white70,
                size: 16,
              ),
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
  final bool isCredit;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isCredit = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCredit
            ? AppColor.creditDark.withOpacity(0.35)
            : const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCredit ? AppColor.creditBorder : color.withOpacity(0.3),
        ),
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
                  style: TextStyle(
                    color: isCredit
                        ? AppColor.creditLight.withOpacity(0.6)
                        : Colors.grey[400],
                    fontSize: 12,
                  ),
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
