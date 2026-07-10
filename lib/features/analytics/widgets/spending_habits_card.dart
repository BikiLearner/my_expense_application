import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/analytics_provider.dart';
import 'all_detail_screens.dart';

class SpendingHabitsCard extends StatelessWidget {
  const SpendingHabitsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AnalyticsProvider, _HabitsData>(
      selector: (_, p) => _HabitsData(
        luxury: p.totalLuxury,
        needed: p.totalNeeded,
        saving: p.totalSaving,
      ),
      builder: (context, data, _) {
        final total = data.luxury + data.needed + data.saving;
        if (total == 0) return const SizedBox();

        final luxPct = data.luxury / total;
        final needPct = data.needed / total;
        final savPct = data.saving / total;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<AnalyticsProvider>(),
                child: const SpendingHabitsDetailScreen(),
              ),
            ),
          ),
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
                    const Text(
                      'Spending Habits',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Row(
                        children: [
                          Text('Details', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 10),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'How you classify your money',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 20),

                // Stacked bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 28,
                    child: Row(
                      children: [
                        if (needPct > 0.01) Expanded(
                          flex: (needPct * 1000).toInt(),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF9A3C), Color(0xFFFFB347)],
                              ),
                            ),
                          ),
                        ),
                        if (luxPct > 0.01) Expanded(
                          flex: (luxPct * 1000).toInt(),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
                              ),
                            ),
                          ),
                        ),
                        if (savPct > 0.01) Expanded(
                          flex: (savPct * 1000).toInt(),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF51CF66), Color(0xFF2ECC71)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Legends
                Row(
                  children: [
                    Expanded(child: _LegendItem(
                      label: 'Needed',
                      amount: data.needed,
                      pct: needPct,
                      color: const Color(0xFFFF9A3C),
                      icon: Icons.check_circle_outline_rounded,
                    )),
                    Expanded(child: _LegendItem(
                      label: 'Luxury',
                      amount: data.luxury,
                      pct: luxPct,
                      color: const Color(0xFFFF6B6B),
                      icon: Icons.diamond_outlined,
                    )),
                    Expanded(child: _LegendItem(
                      label: 'Saved',
                      amount: data.saving,
                      pct: savPct,
                      color: const Color(0xFF51CF66),
                      icon: Icons.savings_outlined,
                    )),
                  ],
                ),

                const SizedBox(height: 16),
                // Insight text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFD166), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getInsight(needPct, luxPct, savPct),
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

  String _getInsight(double need, double lux, double sav) {
    if (sav > 0.3) return 'Great job! You saved over 30% — you\'re building wealth!';
    if (lux > 0.5) return 'Over half spent on luxury — consider reviewing lifestyle spends.';
    if (need > 0.7) return 'Most spending is on essentials — you\'re being practical.';
    return 'Balanced spending across needs, wants, and savings.';
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final double amount;
  final double pct;
  final Color color;
  final IconData icon;

  const _LegendItem({
    required this.label, required this.amount, required this.pct,
    required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text('${(pct * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        Text(
          '₹${_fmt(amount)}',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _HabitsData {
  final double luxury, needed, saving;
  _HabitsData({required this.luxury, required this.needed, required this.saving});
}