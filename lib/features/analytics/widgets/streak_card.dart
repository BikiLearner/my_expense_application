import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/analytics_provider.dart';
import 'all_detail_screens.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AnalyticsProvider, _StreakData>(
      selector: (_, p) => _StreakData(
        current: p.currentStreak,
        longest: p.longestStreak,
        zeroDays: p.zeroSpendDays,
        activeDays: p.activeDays,
        weekday: p.weekdaySpend,
      ),
      builder: (context, data, _) {
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<AnalyticsProvider>(),
              child: const BehaviourDetailScreen(),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Behaviour Insights',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                  ],
                ),
                const SizedBox(height: 20),

                // Streak chips
                Row(
                  children: [
                    _StatChip(
                      label: 'Current Streak',
                      value: '${data.current}d',
                      color: const Color(0xFFFFD166),
                      icon: '🔥',
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Longest Streak',
                      value: '${data.longest}d',
                      color: const Color(0xFF7B8CFF),
                      icon: '⚡',
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Zero-Spend',
                      value: '${data.zeroDays}d',
                      color: const Color(0xFF51CF66),
                      icon: '✅',
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text('Spend by Day of Week',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 12),

                // Weekday bars
                _WeekdayChart(weekday: data.weekday),

                const SizedBox(height: 16),

                // Insight
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🧠', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getWeekdayInsight(data.weekday),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getWeekdayInsight(Map<String, double> weekday) {
    if (weekday.isEmpty) return 'Track more to see patterns.';
    final sorted = weekday.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final peak = sorted.first;
    final low = sorted.last;
    return '${peak.key} is your biggest spend day. ${low.key} is your most frugal day.';
  }
}

class _StatChip extends StatelessWidget {
  final String label, value, icon;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 9), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _WeekdayChart extends StatelessWidget {
  final Map<String, double> weekday;
  const _WeekdayChart({required this.weekday});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = weekday.values.isEmpty
        ? 1.0
        : weekday.values.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) {
        final val = weekday[d] ?? 0.0;
        final pct = maxVal > 0 ? val / maxVal : 0.0;
        final isWeekend = d == 'Sat' || d == 'Sun';

        return Column(
          children: [
            Container(
              width: 34,
              height: 60 * pct + 4,
              decoration: BoxDecoration(
                color: isWeekend
                    ? const Color(0xFFFF9A3C)
                    : const Color(0xFF64FFDA),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 6),
            Text(d.substring(0, 2),
                style: TextStyle(
                  color: isWeekend ? const Color(0xFFFF9A3C) : Colors.grey[600],
                  fontSize: 10,
                )),
          ],
        );
      }).toList(),
    );
  }
}

class _StreakData {
  final int current, longest, zeroDays, activeDays;
  final Map<String, double> weekday;
  _StreakData({
    required this.current, required this.longest,
    required this.zeroDays, required this.activeDays,
    required this.weekday,
  });
}