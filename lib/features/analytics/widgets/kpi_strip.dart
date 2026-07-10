import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../provider/analytics_provider.dart';
import 'kpi_detail_screen.dart';


class KpiStrip extends StatelessWidget {
  const KpiStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<AnalyticsProvider, _KpiData>(
      selector: (_, p) => _KpiData(
        total: p.totalSpent,
        peakDay: p.peakDayAmount,
        peakDate: p.peakDate,
        avgDaily: p.avgDailySpend,
        activeDays: p.activeDays,
        txCount: p.totalTransactions,
      ),
      builder: (context, data, _) {
        return SizedBox(
          height: 140,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              _KpiCard(
                label: 'Total Spent',
                value: '₹${_fmt(data.total)}',
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF64FFDA),
                subtitle: '${data.activeDays} active days',
                onTap: () => _push(context, KpiDetailScreen(kpiType: KpiType.total)),
              ),
              _KpiCard(
                label: 'Peak Day',
                value: '₹${_fmt(data.peakDay)}',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF6B6B),
                subtitle: data.peakDate.isNotEmpty
                    ? _fmtDate(data.peakDate)
                    : 'No data',
                onTap: () => _push(context, KpiDetailScreen(kpiType: KpiType.peak)),
              ),
              _KpiCard(
                label: 'Daily Average',
                value: '₹${_fmt(data.avgDaily)}',
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFF7B8CFF),
                subtitle: 'On spend days',
                onTap: () => _push(context, KpiDetailScreen(kpiType: KpiType.average)),
              ),
              _KpiCard(
                label: 'Transactions',
                value: data.txCount.toString(),
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFFFFD166),
                subtitle: '${(data.total / (data.txCount > 0 ? data.txCount : 1)).toStringAsFixed(0)} avg/tx',
                onTap: () => _push(context, KpiDetailScreen(kpiType: KpiType.transactions)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) =>
        ChangeNotifierProvider.value(
          value: context.read<AnalyticsProvider>(),
          child: screen,
        )));
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  String _fmtDate(String d) {
    try {
      return DateFormat('MMM dd').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141420),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[700], size: 12),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiData {
  final double total, peakDay, avgDaily;
  final String peakDate;
  final int activeDays, txCount;
  _KpiData({
    required this.total, required this.peakDay, required this.avgDaily,
    required this.peakDate, required this.activeDays, required this.txCount,
  });
}