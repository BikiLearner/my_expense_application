// ─── spending_habits_detail_screen.dart ─────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/analytics_provider.dart';

class SpendingHabitsDetailScreen extends StatelessWidget {
  const SpendingHabitsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final total = p.totalLuxury + p.totalNeeded + p.totalSaving;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Spending Habits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full breakdown cards
            _TypeCard(
              type: 'Needed',
              amount: p.totalNeeded,
              pct: total > 0 ? p.totalNeeded / total : 0,
              color: const Color(0xFFFF9A3C),
              icon: Icons.check_circle_rounded,
              description: 'Essential expenses like groceries, rent, transport, bills.',
              emoji: '🏠',
            ),
            const SizedBox(height: 16),
            _TypeCard(
              type: 'Luxury',
              amount: p.totalLuxury,
              pct: total > 0 ? p.totalLuxury / total : 0,
              color: const Color(0xFFFF6B6B),
              icon: Icons.diamond_rounded,
              description: 'Wants and discretionary spends — dining out, entertainment, shopping.',
              emoji: '💎',
            ),
            const SizedBox(height: 16),
            _TypeCard(
              type: 'Saving',
              amount: p.totalSaving,
              pct: total > 0 ? p.totalSaving / total : 0,
              color: const Color(0xFF51CF66),
              icon: Icons.savings_rounded,
              description: 'Money set aside, investments, or explicit saving entries.',
              emoji: '💰',
            ),
            const SizedBox(height: 24),

            // Monthly type breakdown
            _SectionHeader('Monthly Type Breakdown'),
            const SizedBox(height: 12),
            ...p.monthlySavingsRate.keys.map((monthKey) {
              String label = monthKey;
              try { label = DateFormat('MMM yyyy').format(DateTime.parse('$monthKey-01')); } catch (_) {}
              final monthTotal = p.monthlyTotals[monthKey] ?? 0;
              final savRate = p.monthlySavingsRate[monthKey] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141420),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text('₹${_fmt(monthTotal)}', style: const TextStyle(color: Color(0xFF64FFDA), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              Expanded(flex: 60, child: Container(color: const Color(0xFFFF9A3C))),
                              Expanded(flex: 30, child: Container(color: const Color(0xFFFF6B6B))),
                              Expanded(
                                flex: (savRate * 100).toInt().clamp(0, 100),
                                child: Container(color: const Color(0xFF51CF66)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Savings rate: ${(savRate * 100).toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _TypeCard extends StatelessWidget {
  final String type, description, emoji;
  final double amount, pct;
  final Color color;
  final IconData icon;

  const _TypeCard({
    required this.type, required this.amount, required this.pct,
    required this.color, required this.icon, required this.description, required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(type, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${(pct * 100).toStringAsFixed(1)}%',
                        style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('₹${_fmtFull(amount)}',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(description, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtFull(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(2);
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: const Color(0xFF64FFDA)),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: Color(0xFF64FFDA), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ],
    );
  }
}

// ─── monthly_trend_detail_screen.dart ────────────────────────────────────────

class MonthlyTrendDetailScreen extends StatelessWidget {
  const MonthlyTrendDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final sorted = p.monthlyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Monthly Trend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary stats
            Row(
              children: [
                Expanded(child: _MiniStatBox(
                  label: 'Best Month',
                  value: (() {
                    try { return DateFormat('MMM yyyy').format(DateTime.parse('${p.lowestMonth}-01')); } catch(_) { return p.lowestMonth; }
                  })(),
                  sub: '₹${_fmt(p.lowestMonthTotal)}',
                  color: const Color(0xFF51CF66),
                )),
                const SizedBox(width: 12),
                Expanded(child: _MiniStatBox(
                  label: 'Heaviest Month',
                  value: (() {
                    try { return DateFormat('MMM yyyy').format(DateTime.parse('${p.highestMonth}-01')); } catch(_) { return p.highestMonth; }
                  })(),
                  sub: '₹${_fmt(p.highestMonthTotal)}',
                  color: const Color(0xFFFF6B6B),
                )),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader('Month-by-Month'),
            const SizedBox(height: 12),
            ...sorted.map((entry) {
              String label = entry.key;
              try { label = DateFormat('MMMM yyyy').format(DateTime.parse('${entry.key}-01')); } catch(_) {}
              final pct = p.highestMonthTotal > 0 ? entry.value / p.highestMonthTotal : 0.0;
              final prev = sorted.indexOf(entry) > 0
                  ? sorted[sorted.indexOf(entry) - 1].value
                  : null;
              final change = prev != null && prev > 0
                  ? ((entry.value - prev) / prev * 100)
                  : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141420),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            if (change != null)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: change > 0
                                      ? const Color(0xFFFF6B6B).withOpacity(0.15)
                                      : const Color(0xFF51CF66).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: change > 0 ? const Color(0xFFFF6B6B) : const Color(0xFF51CF66),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text('₹${_fmt(entry.value)}',
                                style: const TextStyle(color: Color(0xFF64FFDA), fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        color: const Color(0xFF64FFDA),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _MiniStatBox extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _MiniStatBox({required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          Text(sub, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── category_detail_screen.dart ─────────────────────────────────────────────

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key});

  static const _palette = [
    Color(0xFF64FFDA), Color(0xFF7B8CFF), Color(0xFFFFD166),
    Color(0xFFFF6B6B), Color(0xFF51CF66), Color(0xFFFF9A3C),
    Color(0xFFE64980), Color(0xFF74C0FC), Color(0xFFA9E34B), Color(0xFFCC5DE8),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final sorted = p.categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = p.categoryTotals.values.fold(0.0, (s, v) => s + v);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('All Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sorted.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${sorted.length} categories tracked',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            );
          }
          final entry = sorted[i - 1];
          final color = _palette[(i - 1) % _palette.length];
          final pct = total > 0 ? entry.value / total : 0.0;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141420),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('#$i', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                color: color,
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text('${(pct * 100).toStringAsFixed(1)}%',
                              style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Text('₹${_fmt(entry.value)}',
                    style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

// ─── top_expenses_detail_screen.dart ─────────────────────────────────────────

class TopExpensesDetailScreen extends StatefulWidget {
  const TopExpensesDetailScreen({super.key});

  @override
  State<TopExpensesDetailScreen> createState() => _TopExpensesDetailState();
}

class _TopExpensesDetailState extends State<TopExpensesDetailScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final filtered = _filter == 'All'
        ? p.topExpenses
        : p.topExpenses.where((e) => e.type == _filter.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('All Transactions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: ['All', 'Needed', 'Luxury', 'Saving'].map((f) {
                final isActive = _filter == f;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF64FFDA) : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: isActive ? const Color(0xFF0A0A0F) : Colors.grey[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final exp = filtered[i];
                final typeColors = {
                  'luxury': const Color(0xFFFF6B6B),
                  'needed': const Color(0xFFFF9A3C),
                  'saving': const Color(0xFF51CF66),
                };
                final color = typeColors[exp.type] ?? Colors.grey;
                String dateStr = exp.dateId;
                try { dateStr = DateFormat('MMM dd, yyyy').format(DateTime.parse(exp.dateId)); } catch (_) {}

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141420),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text('${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exp.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${exp.amount.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(exp.type, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── bank_usage_detail_screen.dart ───────────────────────────────────────────

class BankUsageDetailScreen extends StatelessWidget {
  const BankUsageDetailScreen({super.key});

  static const _colors = [
    Color(0xFF64FFDA), Color(0xFF7B8CFF), Color(0xFFFFD166),
    Color(0xFFFF6B6B), Color(0xFF51CF66), Color(0xFFFF9A3C),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final sorted = p.bankUsage.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = p.bankUsage.values.fold(0.0, (s, v) => s + v);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Payment Methods', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sorted.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${sorted.length} payment methods used',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            );
          }
          final entry = sorted[i - 1];
          final color = _colors[(i - 1) % _colors.length];
          final name = p.bankNames[entry.key] ?? entry.key;
          final pct = total > 0 ? entry.value / total : 0.0;
          final txCount = p.topExpenses.where((e) => e.bankId == entry.key).length;

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141420),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                    Text('₹${_fmt(entry.value)}',
                        style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: color,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('${(pct * 100).toStringAsFixed(1)}% of total spend',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const Spacer(),
                    Text('$txCount transactions',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

// ─── savings_detail_screen.dart ──────────────────────────────────────────────

class SavingsDetailScreen extends StatelessWidget {
  const SavingsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final savingsRate = p.totalIncome > 0
        ? (p.totalIncome - p.totalSpent) / p.totalIncome
        : (p.totalSpent > 0 ? p.totalSaving / p.totalSpent : 0.0);

    final sortedMonths = p.monthlySavingsRate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Savings Analysis', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF51CF66).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF51CF66).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Annual Savings Rate', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  const SizedBox(height: 8),
                  Text(
                    '${(savingsRate * 100).toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: savingsRate >= 0 ? const Color(0xFF51CF66) : const Color(0xFFFF6B6B),
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniPill(label: 'Spent', value: '₹${_fmt(p.totalSpent)}', color: const Color(0xFFFF6B6B)),
                      const SizedBox(width: 8),
                      if (p.totalIncome > 0)
                        _MiniPill(label: 'Income', value: '₹${_fmt(p.totalIncome)}', color: const Color(0xFF51CF66)),
                      const SizedBox(width: 8),
                      _MiniPill(label: 'Saved', value: '₹${_fmt(p.totalSaving)}', color: const Color(0xFF64FFDA)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionHeader('Monthly Savings Rate'),
            const SizedBox(height: 12),
            ...sortedMonths.map((entry) {
              String label = entry.key;
              try { label = DateFormat('MMMM yyyy').format(DateTime.parse('${entry.key}-01')); } catch(_) {}
              final rate = entry.value.clamp(0.0, 1.0);
              final color = rate > 0.3
                  ? const Color(0xFF51CF66)
                  : rate > 0.1
                  ? const Color(0xFFFFD166)
                  : const Color(0xFFFF6B6B);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141420),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${(rate * 100).toStringAsFixed(1)}%',
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rate,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          color: color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _MiniPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 9)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── behaviour_detail_screen.dart ────────────────────────────────────────────

class BehaviourDetailScreen extends StatelessWidget {
  const BehaviourDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final maxWeekday = p.weekdaySpend.values.isEmpty
        ? 1.0
        : p.weekdaySpend.values.reduce((a, b) => a > b ? a : b);

    final sortedDays = p.weekdaySpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Behaviour Insights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Streak badges
            Row(
              children: [
                Expanded(child: _BadgeCard(
                  emoji: '🔥',
                  label: 'Current Streak',
                  value: '${p.currentStreak} days',
                  color: const Color(0xFFFFD166),
                )),
                const SizedBox(width: 12),
                Expanded(child: _BadgeCard(
                  emoji: '⚡',
                  label: 'Longest Streak',
                  value: '${p.longestStreak} days',
                  color: const Color(0xFF7B8CFF),
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _BadgeCard(
                  emoji: '✅',
                  label: 'Zero-Spend Days',
                  value: '${p.zeroSpendDays} days',
                  color: const Color(0xFF51CF66),
                )),
                const SizedBox(width: 12),
                Expanded(child: _BadgeCard(
                  emoji: '📅',
                  label: 'Active Days',
                  value: '${p.activeDays} days',
                  color: const Color(0xFF64FFDA),
                )),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader('Day of Week Spending'),
            const SizedBox(height: 12),
            ...sortedDays.map((entry) {
              final pct = maxWeekday > 0 ? entry.value / maxWeekday : 0.0;
              final isWeekend = entry.key == 'Sat' || entry.key == 'Sun';
              final color = isWeekend ? const Color(0xFFFF9A3C) : const Color(0xFF64FFDA);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(entry.key,
                          style: TextStyle(
                            color: isWeekend ? const Color(0xFFFF9A3C) : Colors.white,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          color: color,
                          minHeight: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '₹${_fmt(entry.value)}',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            _SectionHeader('Spend Pattern Insights'),
            const SizedBox(height: 12),
            ..._getInsights(p).map((insight) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF141420),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Text(insight.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(insight.$2, style: TextStyle(color: Colors.grey[300], fontSize: 13))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _getInsights(AnalyticsProvider p) {
    final insights = <(String, String)>[];

    if (p.currentStreak > 7) {
      insights.add(('🔥', 'You\'ve been tracking expenses for ${p.currentStreak} days straight! Keep it up.'));
    }
    if (p.zeroSpendDays > 30) {
      insights.add(('🌟', 'You had ${p.zeroSpendDays} zero-spend days this year — great financial discipline!'));
    }
    if (p.weekdaySpend.isNotEmpty) {
      final sorted = p.weekdaySpend.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      insights.add(('📊', '${sorted.first.key} is your biggest spending day of the week.'));
      insights.add(('💚', '${sorted.last.key} is your most frugal day — well done!'));
    }
    if (p.totalLuxury > p.totalNeeded) {
      insights.add(('⚠️', 'Luxury spends exceed essential spends — consider balancing your budget.'));
    } else {
      insights.add(('✅', 'You spend more on essentials than luxuries — financially responsible pattern.'));
    }
    if (p.avgDailySpend > 0) {
      insights.add(('📈', 'Your average spend on active days is ₹${p.avgDailySpend.toStringAsFixed(0)}.'));
    }
    return insights;
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _BadgeCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _BadgeCard({required this.emoji, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─── heatmap_detail_screen.dart ──────────────────────────────────────────────

class HeatmapDetailScreen extends StatelessWidget {
  const HeatmapDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();
    final sorted = p.dailyTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top20 = sorted.where((e) => e.value > 0).take(20).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Daily Spending', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: top20.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${p.activeDays} days with spending tracked',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            );
          }
          final entry = top20[i - 1];
          String label = entry.key;
          try { label = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.parse(entry.key)); } catch (_) {}
          final pct = top20.first.value > 0 ? entry.value / top20.first.value : 0.0;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF141420),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                    Text('₹${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFF64FFDA), fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: const Color(0xFF64FFDA),
                    minHeight: 4,
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