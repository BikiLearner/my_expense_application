// ─── top_expenses_card.dart ──────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../provider/analytics_provider.dart';
import 'all_detail_screens.dart';


class TopExpensesCard extends StatelessWidget {
  const TopExpensesCard({super.key});

  static const _typeColors = {
    'luxury': Color(0xFFFF6B6B),
    'needed': Color(0xFFFF9A3C),
    'saving': Color(0xFF51CF66),
  };

  @override
  Widget build(BuildContext context) {
    return Selector<AnalyticsProvider, List<TopExpenseEntry>>(
      selector: (_, p) => p.topExpenses,
      builder: (context, top, _) {
        if (top.isEmpty) return const SizedBox();

        final preview = top.take(5).toList();

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<AnalyticsProvider>(),
              child: const TopExpensesDetailScreen(),
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
                    const Text('Biggest Spends',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Top ${top.length}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                ...preview.asMap().entries.map((entry) {
                  final i = entry.key;
                  final exp = entry.value;
                  final typeColor = _typeColors[exp.type] ?? Colors.grey;
                  String dateStr = exp.dateId;
                  try {
                    dateStr = DateFormat('MMM dd').format(DateTime.parse(exp.dateId));
                  } catch (_) {}

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '#${i + 1}',
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exp.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis),
                              Row(
                                children: [
                                  Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      exp.type,
                                      style: TextStyle(color: typeColor, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${_fmt(exp.amount)}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  );
                }),

                if (top.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        'View all ${top.length} transactions →',
                        style: const TextStyle(color: Color(0xFF64FFDA), fontSize: 13),
                      ),
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