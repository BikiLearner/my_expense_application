import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/analytics_provider.dart';
import 'all_detail_screens.dart';

class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({super.key});

  static const _palette = [
    Color(0xFF64FFDA),
    Color(0xFF7B8CFF),
    Color(0xFFFFD166),
    Color(0xFFFF6B6B),
    Color(0xFF51CF66),
    Color(0xFFFF9A3C),
    Color(0xFFE64980),
    Color(0xFF74C0FC),
    Color(0xFFA9E34B),
    Color(0xFFCC5DE8),
  ];

  @override
  Widget build(BuildContext context) {
    return Selector<AnalyticsProvider, Map<String, double>>(
      selector: (_, p) => p.categoryTotals,
      builder: (context, cats, _) {
        if (cats.isEmpty) return const SizedBox();

        final sorted = cats.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top8 = sorted.take(8).toList();
        final total = cats.values.fold(0.0, (s, v) => s + v);

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<AnalyticsProvider>(),
              child: const CategoryDetailScreen(),
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
                    const Text('Top Categories',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${cats.length} total',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bar rows
                ...top8.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cat = entry.value;
                  final color = _palette[i % _palette.length];
                  final pct = total > 0 ? cat.value / total : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cat.key,
                                      style: const TextStyle(color: Colors.white, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '₹${_fmt(cat.value)}',
                                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(pct * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LayoutBuilder(
                          builder: (_, cons) => Stack(
                            children: [
                              Container(
                                height: 5,
                                width: cons.maxWidth,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 600 + i * 80),
                                curve: Curves.easeOutCubic,
                                height: 5,
                                width: cons.maxWidth * pct,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(color: color.withOpacity(0.4), blurRadius: 6),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                if (sorted.length > 8)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${sorted.length - 8} more categories. Tap to view all.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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