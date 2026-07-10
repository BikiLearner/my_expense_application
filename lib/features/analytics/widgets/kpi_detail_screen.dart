import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../provider/analytics_provider.dart';

enum KpiType { total, peak, average, transactions }

class KpiDetailScreen extends StatelessWidget {
  final KpiType kpiType;
  const KpiDetailScreen({super.key, required this.kpiType});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildContent(context, p),
        ),
      ),
    );
  }

  String get _title {
    switch (kpiType) {
      case KpiType.total: return 'Total Spending';
      case KpiType.peak: return 'Peak Day Analysis';
      case KpiType.average: return 'Daily Average';
      case KpiType.transactions: return 'Transaction Analysis';
    }
  }

  List<Widget> _buildContent(BuildContext context, AnalyticsProvider p) {
    switch (kpiType) {
      case KpiType.total:
        return _buildTotalDetail(p);
      case KpiType.peak:
        return _buildPeakDetail(p);
      case KpiType.average:
        return _buildAverageDetail(p);
      case KpiType.transactions:
        return _buildTransactionDetail(p);
    }
  }

  List<Widget> _buildTotalDetail(AnalyticsProvider p) {
    final perMonth = p.totalSpent / 12;
    final perDay365 = p.totalSpent / 365;

    return [
      _HeroStat(
        label: 'Total Spent in ${p.year}',
        value: '₹${_fmtFull(p.totalSpent)}',
        color: const Color(0xFF64FFDA),
      ),
      const SizedBox(height: 24),
      _DetailGrid(items: [
        _GridItem('Per Month (avg)', '₹${_fmt(perMonth)}', const Color(0xFF7B8CFF)),
        _GridItem('Per Day (365)', '₹${_fmt(perDay365)}', const Color(0xFFFFD166)),
        _GridItem('Active Days', p.activeDays.toString(), const Color(0xFF51CF66)),
        _GridItem('Zero-Spend Days', p.zeroSpendDays.toString(), const Color(0xFFFF9A3C)),
        _GridItem('Needed', '₹${_fmt(p.totalNeeded)}', const Color(0xFFFF9A3C)),
        _GridItem('Luxury', '₹${_fmt(p.totalLuxury)}', const Color(0xFFFF6B6B)),
        _GridItem('Saving', '₹${_fmt(p.totalSaving)}', const Color(0xFF51CF66)),
        if (p.totalIncome > 0)
          _GridItem('Income', '₹${_fmt(p.totalIncome)}', const Color(0xFF64FFDA)),
      ]),
      const SizedBox(height: 24),
      _SectionTitle('Monthly Breakdown'),
      const SizedBox(height: 12),
      ...(() {
        final sorted = p.monthlyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
        return sorted.map((entry) {
          String label = entry.key;
          try { label = DateFormat('MMMM yyyy').format(DateTime.parse('${entry.key}-01')); } catch (_) {}
          final pct = p.highestMonthTotal > 0 ? entry.value / p.highestMonthTotal : 0.0;
          return _MonthRow(label: label, amount: entry.value, pct: pct);
        }).toList();
      })(),
    ];
  }

  List<Widget> _buildPeakDetail(AnalyticsProvider p) {
    String peakStr = p.peakDate;
    try { peakStr = DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.parse(p.peakDate)); } catch (_) {}

    // Top 5 peak days
    final topDays = p.dailyTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topDays.take(10).toList();

    return [
      _HeroStat(
        label: 'Peak Day Amount',
        value: '₹${_fmtFull(p.peakDayAmount)}',
        color: const Color(0xFFFF6B6B),
      ),
      const SizedBox(height: 8),
      Text(peakStr, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      const SizedBox(height: 24),
      _SectionTitle('Top 10 Spending Days'),
      const SizedBox(height: 12),
      ...top5.asMap().entries.map((e) {
        String label = e.value.key;
        try { label = DateFormat('EEE, MMM dd').format(DateTime.parse(e.value.key)); } catch (_) {}
        return _RankRow(
          rank: e.key + 1,
          label: label,
          amount: e.value.value,
          maxAmount: top5.first.value,
        );
      }),
    ];
  }

  List<Widget> _buildAverageDetail(AnalyticsProvider p) {
    return [
      _HeroStat(
        label: 'Average per Active Day',
        value: '₹${_fmtFull(p.avgDailySpend)}',
        color: const Color(0xFF7B8CFF),
      ),
      const SizedBox(height: 24),
      _DetailGrid(items: [
        _GridItem('Active Days', p.activeDays.toString(), const Color(0xFF64FFDA)),
        _GridItem('Avg/Week', '₹${_fmt(p.avgDailySpend * 7)}', const Color(0xFFFFD166)),
        _GridItem('Avg/Month', '₹${_fmt(p.avgDailySpend * 30)}', const Color(0xFF7B8CFF)),
        _GridItem('Avg/Year', '₹${_fmt(p.totalSpent)}', const Color(0xFFFF6B6B)),
      ]),
      const SizedBox(height: 24),
      _SectionTitle('Monthly Average Comparison'),
      const SizedBox(height: 12),
      ...p.monthlyTotals.entries.map((entry) {
        String label = entry.key;
        try { label = DateFormat('MMM yyyy').format(DateTime.parse('${entry.key}-01')); } catch (_) {}
        // Estimate days in month
        int daysInMonth = 30;
        try { final dt = DateTime.parse('${entry.key}-01'); daysInMonth = DateUtils.getDaysInMonth(dt.year, dt.month); } catch (_) {}
        final avgThisMonth = entry.value / daysInMonth;

        return _CompareRow(
          label: label,
          value: avgThisMonth,
          baseline: p.avgDailySpend,
        );
      }),
    ];
  }

  List<Widget> _buildTransactionDetail(AnalyticsProvider p) {
    final avgPerTx = p.totalTransactions > 0 ? p.totalSpent / p.totalTransactions : 0.0;

    // Category frequency (count how many items per category)
    final catCounts = <String, int>{};
    for (final exp in p.topExpenses) {
      catCounts[exp.title] = (catCounts[exp.title] ?? 0) + 1;
    }
    final sortedCats = catCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return [
      _HeroStat(
        label: 'Total Transactions',
        value: p.totalTransactions.toString(),
        color: const Color(0xFFFFD166),
      ),
      const SizedBox(height: 24),
      _DetailGrid(items: [
        _GridItem('Avg per Transaction', '₹${_fmt(avgPerTx)}', const Color(0xFF64FFDA)),
        _GridItem('Avg per Day', '${(p.totalTransactions / (p.activeDays > 0 ? p.activeDays : 1)).toStringAsFixed(1)}/day', const Color(0xFF7B8CFF)),
        _GridItem('Active Days', p.activeDays.toString(), const Color(0xFFFFD166)),
        _GridItem('Zero-Spend Days', p.zeroSpendDays.toString(), const Color(0xFF51CF66)),
      ]),
      const SizedBox(height: 24),
      _SectionTitle('Most Frequent Categories'),
      const SizedBox(height: 12),
      ...sortedCats.take(10).map((entry) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(entry.key, style: const TextStyle(color: Colors.white, fontSize: 14))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD166).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${entry.value}x', style: const TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      )),
    ];
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  String _fmtFull(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)} Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(2)} L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(2);
  }
}

// ── Shared detail screen widgets ─────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _HeroStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

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

class _DetailGrid extends StatelessWidget {
  final List<_GridItem> items;
  const _DetailGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            const SizedBox(height: 4),
            Text(item.value, style: TextStyle(color: item.color, fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      )).toList(),
    );
  }
}

class _GridItem {
  final String label, value;
  final Color color;
  _GridItem(this.label, this.value, this.color);
}

class _MonthRow extends StatelessWidget {
  final String label;
  final double amount, pct;
  const _MonthRow({required this.label, required this.amount, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
              Text('₹${_fmt(amount)}',
                  style: const TextStyle(color: Color(0xFF64FFDA), fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.05),
              color: const Color(0xFF64FFDA),
              minHeight: 5,
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

class _RankRow extends StatelessWidget {
  final int rank;
  final String label;
  final double amount, maxAmount;
  const _RankRow({required this.rank, required this.label, required this.amount, required this.maxAmount});

  @override
  Widget build(BuildContext context) {
    final pct = maxAmount > 0 ? amount / maxAmount : 0.0;
    final color = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
        ? const Color(0xFFC0C0C0)
        : rank == 3
        ? const Color(0xFFCD7F32)
        : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('#$rank', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: const Color(0xFFFF6B6B),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('₹${_fmt(amount)}',
              style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
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

class _CompareRow extends StatelessWidget {
  final String label;
  final double value, baseline;
  const _CompareRow({required this.label, required this.value, required this.baseline});

  @override
  Widget build(BuildContext context) {
    final isAbove = value > baseline;
    final diff = ((value - baseline) / (baseline > 0 ? baseline : 1) * 100);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          Text('₹${_fmt(value)}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAbove
                  ? const Color(0xFFFF6B6B).withOpacity(0.15)
                  : const Color(0xFF51CF66).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isAbove ? '+' : ''}${diff.toStringAsFixed(0)}%',
              style: TextStyle(
                color: isAbove ? const Color(0xFFFF6B6B) : const Color(0xFF51CF66),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(2);
  }
}