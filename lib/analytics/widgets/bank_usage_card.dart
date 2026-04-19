import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/analytics_provider.dart';
import 'all_detail_screens.dart';

class BankUsageCard extends StatelessWidget {
  const BankUsageCard({super.key});

  static const _colors = [
    Color(0xFF64FFDA), Color(0xFF7B8CFF), Color(0xFFFFD166),
    Color(0xFFFF6B6B), Color(0xFF51CF66), Color(0xFFFF9A3C),
  ];

  @override
  Widget build(BuildContext context) {
    return Selector<AnalyticsProvider, _BankData>(
      selector: (_, p) => _BankData(usage: p.bankUsage, names: p.bankNames),
      builder: (context, data, _) {
        if (data.usage.isEmpty) return const SizedBox();

        final sorted = data.usage.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final total = data.usage.values.fold(0.0, (s, v) => s + v);

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<AnalyticsProvider>(),
              child: const BankUsageDetailScreen(),
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
                const Text('Payment Methods',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Where your money flows from',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 20),

                // Horizontal segmented bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 20,
                    child: Row(
                      children: sorted.asMap().entries.map((entry) {
                        final i = entry.key;
                        final bank = entry.value;
                        final pct = total > 0 ? bank.value / total : 0.0;
                        return Expanded(
                          flex: (pct * 1000).toInt(),
                          child: Container(
                            color: _colors[i % _colors.length],
                            margin: const EdgeInsets.only(right: 2),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                ...sorted.asMap().entries.map((entry) {
                  final i = entry.key;
                  final bank = entry.value;
                  final color = _colors[i % _colors.length];
                  final name = data.names[bank.key] ?? bank.key;
                  final pct = total > 0 ? bank.value / total : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(name,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('${(pct * 100).toStringAsFixed(1)}%',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        const SizedBox(width: 12),
                        Text('₹${_fmt(bank.value)}',
                            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }),
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

class _BankData {
  final Map<String, double> usage;
  final Map<String, String> names;
  _BankData({required this.usage, required this.names});
}