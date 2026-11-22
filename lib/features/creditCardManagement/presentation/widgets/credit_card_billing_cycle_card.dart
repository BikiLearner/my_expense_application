import 'package:expence_app/core/constants/date_constant.dart';
import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:flutter/material.dart';

import 'credit_card_info_chip.dart';

class CreditCardBillingCycleCard extends StatelessWidget {
  final BillingCycleModel billingCycle;
  final Color accent;
  final bool isCurrent;
  final VoidCallback onTap;

  const CreditCardBillingCycleCard({
    super.key,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accent.withOpacity(.35)),
                    ),
                    child: Text(
                      isCurrent ? 'Current' : billingCycle.status,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                  Expanded(
                    child: CreditCardInfoChip(
                      label: 'Needed',
                      value: (billingCycle.needed ?? 0).toString(),
                      color: Colors.white.withOpacity(.06),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CreditCardInfoChip(
                      label: 'Luxury',
                      value: (billingCycle.luxury ?? 0).toString(),
                      color: Colors.white.withOpacity(.06),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CreditCardInfoChip(
                      label: 'Saving',
                      value: (billingCycle.saving ?? 0).toString(),
                      color: Colors.white.withOpacity(.06),
                    ),
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
