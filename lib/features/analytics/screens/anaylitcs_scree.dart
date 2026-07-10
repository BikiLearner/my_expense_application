import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/analytics_provider.dart';
import '../widgets/analytics_header.dart';
import '../widgets/bank_usage_card.dart';
import '../widgets/category_breakdown_card.dart';
import '../widgets/daily_heatmap_card.dart';
import '../widgets/kpi_strip.dart';
import '../widgets/monthly_trend_card.dart';
import '../widgets/savings_rate_card.dart';
import '../widgets/spending_habits_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/top_expenses_card.dart';


class ExpenseAnalyticsScreen extends StatelessWidget {
  final String year;
  const ExpenseAnalyticsScreen({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AnalyticsProvider(year: year)..loadAll(),
      child: _AnalyticsBody(year: year),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  final String year;
  const _AnalyticsBody({required this.year});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Selector<AnalyticsProvider, AnalyticsState>(
        selector: (_, p) => p.state,
        builder: (context, state, _) {
          if (state == AnalyticsState.loading) {
            return _buildLoader();
          }
          if (state == AnalyticsState.empty) {
            return _buildEmpty(context);
          }
          return _buildContent(context);
        },
      ),
    );
  }

  Widget _buildLoader() {
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFF64FFDA),
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Crunching your data...',
              style: TextStyle(color: Color(0xFF64FFDA), fontSize: 14, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('$year Analytics', style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: const Icon(Icons.bar_chart_rounded, size: 50, color: Color(0xFF64FFDA)),
            ),
            const SizedBox(height: 24),
            const Text('No data for this year', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Start tracking expenses to see insights', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Animated App Bar Header
        SliverToBoxAdapter(child: AnalyticsHeader(year: year)),

        // 2. KPI Strip (4 hero numbers)
        const SliverToBoxAdapter(child: SizedBox(height: 4)),
        const SliverToBoxAdapter(child: KpiStrip()),

        // 3. Spending Habits (Needs / Luxury / Saving)
        _sectionGap(),
        _sectionLabel(context, 'SPENDING HABITS'),
        const SliverToBoxAdapter(child: SpendingHabitsCard()),

        // 4. Monthly Trend Bar Chart
        _sectionGap(),
        _sectionLabel(context, 'MONTHLY TREND'),
        SliverToBoxAdapter(child: MonthlyTrendCard()),

        // 5. Category Breakdown
        _sectionGap(),
        _sectionLabel(context, 'CATEGORY BREAKDOWN'),
        const SliverToBoxAdapter(child: CategoryBreakdownCard()),

        // 6. Daily Spending Heatmap
        _sectionGap(),
        _sectionLabel(context, 'DAILY HEATMAP'),
        const SliverToBoxAdapter(child: DailyHeatmapCard()),

        // 7. Top Expenses
        _sectionGap(),
        _sectionLabel(context, 'BIGGEST SPENDS'),
        const SliverToBoxAdapter(child: TopExpensesCard()),

        // 8. Bank Usage
        _sectionGap(),
        _sectionLabel(context, 'PAYMENT METHODS'),
        const SliverToBoxAdapter(child: BankUsageCard()),

        // 9. Savings Rate
        _sectionGap(),
        _sectionLabel(context, 'SAVINGS RATE'),
        const SliverToBoxAdapter(child: SavingsRateCard()),

        // 10. Streaks & Behaviour
        _sectionGap(),
        _sectionLabel(context, 'BEHAVIOUR INSIGHTS'),
        const SliverToBoxAdapter(child: StreakCard()),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  SliverToBoxAdapter _sectionGap() =>
      const SliverToBoxAdapter(child: SizedBox(height: 28));

  SliverToBoxAdapter _sectionLabel(BuildContext ctx, String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(width: 3, height: 14, color: const Color(0xFF64FFDA)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64FFDA),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}