import 'package:expence_app/core/constants/date_constant.dart';
import 'package:expence_app/core/theme/app_color.dart';
import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../provider/credit_card_payment_provider.dart';
import 'billing_detials_screen.dart';

/// Full details screen for a single credit card.
///
/// Shows:
///  - The card itself, rendered like a physical credit card.
///  - Quick stats: total expense / highest expense (current cycle) and
///    credit utilisation.
///  - The current billing cycle summary with a button to drill into it.
///  - A scrollable history of past billing cycles, each tappable.
class CreditCardDetailsScreen extends StatelessWidget {


  const CreditCardDetailsScreen({super.key,});

  @override
  Widget build(BuildContext context) {
    final creditCard = context.select<CreditCardDetailsProvider, CreditCardModel>(
          (provider) => provider.creditCard,
    );

    final palette = AppColor.paletteFor(
      creditCard.bankName + creditCard.cardName,
    );

    return Scaffold(
      backgroundColor: AppColor.creditSurface,
      appBar: AppBar(
        backgroundColor: AppColor.creditSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Card Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Selector<CreditCardDetailsProvider, BillingCycleModel?>(
        selector: (_, provider) =>
            provider.creditCard.creditCardId == creditCard.creditCardId
            ? provider.currentBillingCycle
            : null,
        builder: (context, currentCycle, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _CreditCardVisual(creditCard: creditCard, palette: palette),
              const SizedBox(height: 20),
              _StatsRow(creditCard: creditCard, currentCycle: currentCycle),
              const SizedBox(height: 20),
              _UsageCard(creditCard: creditCard, currentCycle: currentCycle),
              const SizedBox(height: 28),
              const _SectionTitle(title: 'Current Billing Cycle'),
              const SizedBox(height: 12),
              currentCycle == null
                  ? _EmptyCycleNotice(
                      message: 'No active billing cycle yet for this card.',
                    )
                  : _BillingCycleCard(
                      billingCycle: currentCycle,
                      accent: palette.accent,
                      isCurrent: true,
                      onTap: () {
                        context.push(
                          AppRoutes.billingDetails,
                          extra: (
                          context.read<CreditCardDetailsProvider>(),
                          creditCard,
                          currentCycle,
                          true, // or false
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 28),
              const _SectionTitle(title: 'Billing Cycle History'),
              const SizedBox(height: 12),
              _BillingCycleHistoryList(
                creditCard: creditCard,
                currentCycleId: currentCycle?.billingCycleId,
                accent: palette.accent,
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Section title
// ─────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: .2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Card visual (top banner)
// ─────────────────────────────────────────────────────────────────────────
class _CreditCardVisual extends StatelessWidget {
  final CreditCardModel creditCard;
  final CreditCardPalette palette;

  const _CreditCardVisual({required this.creditCard, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradient,
        ),
        border: Border.all(color: Colors.white.withOpacity(.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withOpacity(.45),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(.05),
                  width: 24,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          palette.accent.withOpacity(.9),
                          palette.accent.withOpacity(.5),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.wifi_rounded,
                    color: Colors.white.withOpacity(.55),
                    size: 20,
                  ),
                  const Spacer(),
                  _StatusPill(isActive: creditCard.isActive),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                creditCard.cardName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                creditCard.bankName.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'CREDIT LIMIT',
                style: TextStyle(
                  color: Colors.white.withOpacity(.55),
                  letterSpacing: 1.3,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹ ${creditCard.creditLimit.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.receipt_long_rounded,
                      label: 'Statement',
                      value: '${creditCard.statementDay}',
                      accent: palette.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.event_rounded,
                      label: 'Due Date',
                      value: '${creditCard.dueDay}',
                      accent: palette.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;

  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColor.creditSoft : AppColor.creditDue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color accent;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: accent.withOpacity(.85)),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stats row: Total expense / Highest expense (current cycle)
// ─────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final CreditCardModel creditCard;
  final BillingCycleModel? currentCycle;

  const _StatsRow({required this.creditCard, required this.currentCycle});

  @override
  Widget build(BuildContext context) {
    final totalExpense = currentCycle?.totalAmount ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.stacked_line_chart_rounded,
            label: 'Total Expense',
            value: '₹${totalExpense.toStringAsFixed(0)}',
            color: AppColor.creditAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Selector<CreditCardDetailsProvider, double>(
            selector: (_, provider) => provider.highestCurrentMonth,
            builder: (context, highest, _) {
              return _StatCard(
                icon: Icons.trending_up_rounded,
                label: 'Highest Expense',
                value: '₹${highest.toStringAsFixed(0)}',
                color: AppColor.creditDue,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(.55),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Usage card (limit vs used, current cycle)
// ─────────────────────────────────────────────────────────────────────────
class _UsageCard extends StatelessWidget {
  final CreditCardModel creditCard;
  final BillingCycleModel? currentCycle;

  const _UsageCard({required this.creditCard, required this.currentCycle});

  @override
  Widget build(BuildContext context) {
    final used = currentCycle?.totalAmount ?? 0;
    final limit = creditCard.creditLimit;
    final ratio = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final available = (limit - used).clamp(0, double.infinity);

    final barColor = ratio >= .9
        ? AppColor.creditDue
        : ratio >= .6
        ? Colors.orangeAccent
        : AppColor.creditSoft;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CREDIT UTILISATION',
                style: TextStyle(
                  color: Colors.white.withOpacity(.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .8,
                ),
              ),
              Text(
                '${(ratio * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: barColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(.08),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _UsageLegend(label: 'Used', value: used, color: barColor),
              _UsageLegend(
                label: 'Available',
                value: available.toDouble(),
                color: AppColor.creditAccent,
              ),
              _UsageLegend(label: 'Limit', value: limit, color: Colors.white54),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageLegend extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _UsageLegend({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(.5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Current billing cycle card + history list
// ─────────────────────────────────────────────────────────────────────────
class _BillingCycleCard extends StatelessWidget {
  final BillingCycleModel billingCycle;
  final Color accent;
  final bool isCurrent;
  final VoidCallback onTap;

  const _BillingCycleCard({
    required this.billingCycle,
    required this.accent,
    required this.onTap,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(.05),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrent
                  ? accent.withOpacity(.35)
                  : Colors.white.withOpacity(.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 15,
                        color: accent.withOpacity(.9),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateConstants.ddMMMyyyy(billingCycle.startDate)} - '
                        '${DateConstants.ddMMMyyyy(billingCycle.endDate)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  _CyclePill(
                    label: isCurrent ? 'Current' : billingCycle.status,
                    accent: accent,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '₹${billingCycle.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total spend this cycle',
                style: TextStyle(
                  color: Colors.white.withOpacity(.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _CategoryTag(
                    label: 'Saving',
                    value: billingCycle.saving ?? 0,
                  ),
                  const SizedBox(width: 8),
                  _CategoryTag(
                    label: 'Needed',
                    value: billingCycle.needed ?? 0,
                  ),
                  const SizedBox(width: 8),
                  _CategoryTag(
                    label: 'Luxury',
                    value: billingCycle.luxury ?? 0,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16, color: accent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CyclePill extends StatelessWidget {
  final String label;
  final Color accent;

  const _CyclePill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withOpacity(.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(.35)),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(
          color: accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String label;
  final double value;

  const _CategoryTag({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(.5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '₹${value.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCycleNotice extends StatelessWidget {
  final String message;

  const _EmptyCycleNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.white.withOpacity(.4),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(.55),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingCycleHistoryList extends StatelessWidget {
  final CreditCardModel creditCard;
  final String? currentCycleId;
  final Color accent;

  const _BillingCycleHistoryList({
    required this.creditCard,
    required this.currentCycleId,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<CreditCardDetailsProvider, List<BillingCycleModel>>(
      selector: (context, p) => p.billingCyclesPerCreditCard,
      builder: (context, cycles, _) {
        if (cycles.isEmpty) {
          return const _EmptyCycleNotice(
            message: 'No past billing cycles yet.',
          );
        }

        return Column(
          children: cycles
              .map(
                (cycle) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BillingCycleCard(
                    billingCycle: cycle,
                    accent: accent,
                    onTap: () {
                      context.push(
                        AppRoutes.billingDetails,
                        extra: (
                        context.read<CreditCardDetailsProvider>(),
                        creditCard,
                        cycle,
                        cycle.billingCycleId == currentCycleId,
                        ),
                      );
                    },
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
