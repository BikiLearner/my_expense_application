import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provider/analytics_provider.dart';
import 'all_detail_screens.dart';

class MonthlyTrendCard extends StatefulWidget {
  const MonthlyTrendCard({super.key});

  @override
  State<MonthlyTrendCard> createState() => _MonthlyTrendCardState();
}

class _MonthlyTrendCardState extends State<MonthlyTrendCard>
    with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  late AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AnalyticsProvider, Map<String, double>>(
      selector: (_, p) => p.monthlyTotals,
      builder: (context, monthlyTotals, _) {
        final provider = context.read<AnalyticsProvider>();
        final maxVal = provider.highestMonthTotal;

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: provider,
              child: const MonthlyTrendDetailScreen(),
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
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Monthly Trend',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    if (maxVal > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B8CFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Peak: ₹${_fmt(maxVal)}',
                          style: const TextStyle(color: Color(0xFF7B8CFF), fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Bar chart
                SizedBox(
                  height: 160,
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) => LayoutBuilder(
                      builder: (ctx, cons) {
                        final barW = (cons.maxWidth / 12) - 6;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(12, (i) {
                            final monthNum = (i + 1).toString().padLeft(2, '0');
                            final key = monthlyTotals.keys.firstWhere(
                                    (k) => k.endsWith('-$monthNum'),
                                orElse: () => '');
                            final amount = key.isEmpty ? 0.0 : (monthlyTotals[key] ?? 0.0);
                            final pct = maxVal == 0 ? 0.0 : (amount / maxVal) * _anim.value;
                            final isHovered = _hoveredIndex == i;
                            final barColor = amount == 0
                                ? Colors.white.withOpacity(0.04)
                                : isHovered
                                ? const Color(0xFFFFD166)
                                : const Color(0xFF64FFDA);

                            return GestureDetector(
                              onTapDown: (_) => setState(() => _hoveredIndex = i),
                              onTapUp: (_) => setState(() => _hoveredIndex = null),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isHovered && amount > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      margin: const EdgeInsets.only(bottom: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFD166),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '₹${_fmt(amount)}',
                                        style: const TextStyle(
                                          color: Color(0xFF0A0A0F),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: barW,
                                    height: (cons.maxHeight - 30) * (amount == 0 ? 0.02 : pct * 0.95) + 2,
                                    decoration: BoxDecoration(
                                      color: barColor,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: isHovered
                                          ? [BoxShadow(color: const Color(0xFFFFD166).withOpacity(0.4), blurRadius: 10)]
                                          : amount > 0
                                          ? [BoxShadow(color: const Color(0xFF64FFDA).withOpacity(0.2), blurRadius: 6)]
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat('MMM').format(DateTime(2024, i + 1)),
                                    style: TextStyle(
                                      color: isHovered ? const Color(0xFFFFD166) : Colors.grey[700],
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                // Best/Worst month row
                Selector<AnalyticsProvider, _MonthExtremes>(
                  selector: (_, p) => _MonthExtremes(
                    high: p.highestMonth,
                    low: p.lowestMonth,
                    highVal: p.highestMonthTotal,
                    lowVal: p.lowestMonthTotal,
                  ),
                  builder: (_, ex, __) => Row(
                    children: [
                      Expanded(child: _ExtremeTile(
                        label: 'Biggest Month',
                        monthKey: ex.high,
                        amount: ex.highVal,
                        color: const Color(0xFFFF6B6B),
                        icon: Icons.trending_up_rounded,
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _ExtremeTile(
                        label: 'Lightest Month',
                        monthKey: ex.low,
                        amount: ex.lowVal,
                        color: const Color(0xFF51CF66),
                        icon: Icons.trending_down_rounded,
                      )),
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

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _ExtremeTile extends StatelessWidget {
  final String label, monthKey;
  final double amount;
  final Color color;
  final IconData icon;

  const _ExtremeTile({
    required this.label, required this.monthKey,
    required this.amount, required this.color, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    String monthStr = monthKey;
    try {
      if (monthKey.isNotEmpty) {
        monthStr = DateFormat('MMM yyyy').format(DateTime.parse('$monthKey-01'));
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                Text(monthStr, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                Text(
                  '₹${_fmt(amount)}',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _MonthExtremes {
  final String high, low;
  final double highVal, lowVal;
  _MonthExtremes({required this.high, required this.low, required this.highVal, required this.lowVal});
}