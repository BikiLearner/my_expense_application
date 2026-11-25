import 'package:expence_app/core/constants/date_constant.dart';
import 'package:expence_app/core/utils/compact_number_formatter.dart';
import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:flutter/material.dart';

import 'credit_card_status_pill.dart';

class CreditCardBillingCycleCard extends StatelessWidget {
  final BillingCycleModel billingCycle;
  final Color accent;
  final VoidCallback onTap;
  final bool showButton;

  const CreditCardBillingCycleCard({
    super.key,
    required this.billingCycle,
    required this.accent,
    required this.onTap,
    this.showButton = true,
  });

  static const _neededColor = Color(0xFF4FC3F7);
  static const _luxuryColor = Color(0xFFBA68C8);

  @override
  Widget build(BuildContext context) {
    final isPaid = billingCycle.isPaid ?? false;
    final needed = (billingCycle.needed ?? 0).toDouble();
    final luxury = (billingCycle.luxury ?? 0).toDouble();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(.18),
            Colors.white.withOpacity(.04),
          ],
        ),
        border: Border.all(color: accent.withOpacity(.25)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(

          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildAmountRow(isPaid),
                const SizedBox(height: 20),
                _SpendBar(
                  needed: needed,
                  luxury: luxury,
                  neededColor: _neededColor,
                  luxuryColor: _luxuryColor,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _LegendItem(
                        color: _neededColor,
                        label: 'Needed',
                        value: needed,
                      ),
                    ),
                    Expanded(
                      child: _LegendItem(
                        color: _luxuryColor,
                        label: 'Luxury',
                        value: luxury,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (showButton) ...[
                  Divider(color: Colors.white.withOpacity(.08), height: 1),
                  const SizedBox(height: 12),
                  _buildFooter(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accent.withOpacity(.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 16,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${DateConstants.ddMMMyyyy(billingCycle.startDate)} - '
                      '${DateConstants.ddMMMyyyy(billingCycle.endDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CreditCardStatusPill(
          value: billingCycle.status,
          color: accent,
        ),
      ],
    );
  }

  Widget _buildAmountRow(bool isPaid) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL SPEND',
                style: TextStyle(
                  color: Colors.white.withOpacity(.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '₹${CompactNumberFormatter.format(billingCycle.totalAmount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _PaidBadge(isPaid: isPaid),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'See all transactions',
          style: TextStyle(
            color: Colors.white.withOpacity(.55),
            fontSize: 12,
          ),
        ),
        Row(
          children: [
            Text(
              'View Details',
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: accent.withOpacity(.18),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded, size: 14, color: accent),
            ),
          ],
        ),
      ],
    );
  }
}

class _PaidBadge extends StatelessWidget {
  final bool isPaid;

  const _PaidBadge({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final color = isPaid ? Colors.greenAccent.shade400 : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            isPaid ? 'Paid' : 'Not Paid',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendBar extends StatelessWidget {
  final double needed;
  final double luxury;
  final Color neededColor;
  final Color luxuryColor;

  const _SpendBar({
    required this.needed,
    required this.luxury,
    required this.neededColor,
    required this.luxuryColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = needed + luxury;

    Widget segment(double value, Color color) {
      return Expanded(
        flex: (value / total * 1000).round().clamp(1, 1000),
        child: Container(color: color),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 8,
        child: total <= 0
            ? Container(color: Colors.white.withOpacity(.08))
            : Row(
          children: [
            if (needed > 0) segment(needed, neededColor),
            if (luxury > 0) segment(luxury, luxuryColor),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(.55),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}