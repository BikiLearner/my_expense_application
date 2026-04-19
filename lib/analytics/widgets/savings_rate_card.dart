// ─── savings_rate_card.dart ──────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provider/analytics_provider.dart';
import 'all_detail_screens.dart';

class SavingsRateCard extends StatelessWidget {
  const SavingsRateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AnalyticsProvider, _SavData>(
      selector: (_, p) => _SavData(
        totalIncome: p.totalIncome,
        totalSaving: p.totalSaving,
        totalSpent: p.totalSpent,
        monthly: p.monthlySavingsRate,
      ),
      builder: (context, data, _) {
        final savingsRate = data.totalIncome > 0
            ? (data.totalIncome - data.totalSpent) / data.totalIncome
            : (data.totalSpent > 0 ? data.totalSaving / data.totalSpent : 0.0);

        final clampedRate = savingsRate.clamp(-1.0, 1.0);

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<AnalyticsProvider>(),
              child: const SavingsDetailScreen(),
            ),
          )),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141420),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Savings Rate',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular gauge
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: clampedRate.abs(),
                            backgroundColor: Colors.white.withOpacity(0.05),
                            color: clampedRate >= 0.2
                                ? const Color(0xFF51CF66)
                                : clampedRate >= 0
                                ? const Color(0xFFFFD166)
                                : const Color(0xFFFF6B6B),
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(clampedRate * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: clampedRate >= 0
                                      ? const Color(0xFF51CF66)
                                      : const Color(0xFFFF6B6B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text('savings', style: TextStyle(color: Colors.grey[600], fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Stats column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data.totalIncome > 0) ...[
                            _SavRow(
                              label: 'Income',
                              value: '₹${_fmt(data.totalIncome)}',
                              color: const Color(0xFF51CF66),
                            ),
                            const SizedBox(height: 8),
                          ],
                          _SavRow(
                            label: 'Spent',
                            value: '₹${_fmt(data.totalSpent)}',
                            color: const Color(0xFFFF6B6B),
                          ),
                          const SizedBox(height: 8),
                          _SavRow(
                            label: 'Saved',
                            value: '₹${_fmt(data.totalSaving)}',
                            color: const Color(0xFF64FFDA),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _getRateInsight(clampedRate),
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (data.monthly.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Monthly Savings Rate',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(12, (i) {
                        final monthKey = data.monthly.keys.firstWhere(
                              (k) => k.endsWith('-${(i + 1).toString().padLeft(2, '0')}'),
                          orElse: () => '',
                        );
                        final rate = monthKey.isEmpty ? 0.0 : (data.monthly[monthKey] ?? 0.0);
                        final clamped = rate.clamp(0.0, 1.0);

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: 40 * clamped + 2,
                            decoration: BoxDecoration(
                              color: clamped > 0.3
                                  ? const Color(0xFF51CF66)
                                  : clamped > 0.1
                                  ? const Color(0xFFFFD166)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D']
                        .map((m) => Text(m, style: TextStyle(color: Colors.grey[700], fontSize: 9)))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRateInsight(double rate) {
    if (rate >= 0.3) return '🏆 Excellent! You\'re saving 30%+ of income.';
    if (rate >= 0.2) return '✅ Good discipline — above the 20% benchmark.';
    if (rate >= 0.1) return '⚠️ Saving 10-20% — room for improvement.';
    if (rate >= 0) return '🔴 Low savings rate — review expenses.';
    return '🚨 Spending exceeds income — review immediately.';
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _SavRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SavRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SavData {
  final double totalIncome, totalSaving, totalSpent;
  final Map<String, double> monthly;
  _SavData({required this.totalIncome, required this.totalSaving, required this.totalSpent, required this.monthly});
}