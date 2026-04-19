import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/analytics_provider.dart';

class AnalyticsHeader extends StatelessWidget {
  final String year;
  const AnalyticsHeader({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF0A0A0F)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button + title row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$year Deep Dive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'Full Year Analytics',
                        style: TextStyle(color: Color(0xFF64FFDA), fontSize: 12, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Refresh button
                  GestureDetector(
                    onTap: () => context.read<AnalyticsProvider>().loadAll(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64FFDA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF64FFDA).withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Color(0xFF64FFDA), size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Year comparison blurb
              Selector<AnalyticsProvider, double>(
                selector: (_, p) => p.totalSpent,
                builder: (_, totalSpent, __) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF64FFDA).withOpacity(0.08),
                          const Color(0xFF64FFDA).withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF64FFDA).withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF64FFDA).withOpacity(0.15),
                          ),
                          child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF64FFDA), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Expenditure',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                '₹${_formatFull(totalSpent)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFull(double value) {
    if (value >= 10000000) return '${(value / 10000000).toStringAsFixed(2)} Cr';
    if (value >= 100000) return '${(value / 100000).toStringAsFixed(2)} L';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}