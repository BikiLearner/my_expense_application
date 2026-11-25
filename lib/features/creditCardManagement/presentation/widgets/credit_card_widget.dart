import 'package:expence_app/core/theme/app_color.dart';
import 'package:expence_app/core/utils/compact_number_formatter.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:expence_app/features/creditCardManagement/presentation/widgets/credit_card_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/long_press_message.dart';
import 'credit_card_info_chip.dart';

class CreditCardWidget extends StatelessWidget {
  final CreditCardModel creditCard;
  final CreditCardPalette palette;
  final double? currentUsage;
  final Function() onTap;
  final bool hasBillingCycle;

  const CreditCardWidget({
    super.key,
    required this.creditCard,
    required this.palette,
    this.currentUsage = 0.0,
    required this.onTap,
    required this.hasBillingCycle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Stack(
            children: [
              // Subtle decorative ring for texture
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
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header — chip, contactless icon, status pill
                    Row(
                      children: [
                        // EMV-style metallic chip
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
                        Row(
                          spacing: 8,
                          children: [
                            IconButton(
                              onPressed: () {
                                context.push(AppRoutes.creditForm, extra: creditCard);
                              },
                              icon: const Icon(Icons.edit_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.06),
                                foregroundColor: const Color(0xFF1AB6FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                              ),
                            ),
                            CreditCardStatusPill(
                              value: creditCard.isActive ? 'Active' : 'Inactive',
                            ),
                          ],
                        ),
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
                      "CREDIT LIMIT",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.55),
                        letterSpacing: 1.3,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "₹ ${CompactNumberFormatter.format(creditCard.creditLimit)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: CreditCardInfoChip(
                            icon: Icons.receipt_long_rounded,
                            label: "Statement",
                            value: "${creditCard.statementDay}",
                            color: palette.accent,
                          ),
                        ),
                        Expanded(
                          child: LongPressMessage(
                            message: hasBillingCycle
                                ? "Total amount used is ₹${currentUsage?.toStringAsFixed(2)}"
                                : "No active billing cycle. No expenses are currently recorded.",
                            child: InkWell(
                              onTap: () => context
                                  .read<CreditExpenseProvider>()
                                  .setToggleUtilisationBox(),
                              child: CreditCardInfoChip(
                                icon: Icons.payments_rounded,
                                label: "Current Use",
                                value: CompactNumberFormatter.format(
                                  currentUsage ?? 0,
                                ),
                                color: palette.accent,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CreditCardInfoChip(
                            icon: Icons.event_rounded,
                            label: "Due Date",
                            value: "${creditCard.dueDay}",
                            color: palette.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Selector<CreditExpenseProvider, bool>(
                      selector: (_, provider) => provider.toggleUtilisationBox,
                      builder: (context, showUtilisation, child) {
                        return showUtilisation
                            ? _UsageCard(
                                creditCard: creditCard,
                                currentUsage: currentUsage,
                              )
                            : const SizedBox.shrink();
                      },
                    ),
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

// 📊 Info Chip Widget

class _UsageCard extends StatelessWidget {
  final CreditCardModel creditCard;
  final double? currentUsage;

  const _UsageCard({required this.creditCard, this.currentUsage});

  @override
  Widget build(BuildContext context) {
    final used = currentUsage ?? 0.0;
    final limit = creditCard.creditLimit;

    final rawRatio = limit <= 0 ? 0.0 : used / limit;
    final ratio = rawRatio.clamp(0.0, 1.0);

    final available = (limit - used).clamp(0.0, double.infinity);

    final barColor = rawRatio > 1.0
        ? AppColor.paletteRed
        : rawRatio >= 0.9
        ? AppColor.palettePink
        : rawRatio >= 0.6
        ? AppColor.paletteOrange
        : rawRatio > 0.3
        ? AppColor.paletteLightBlue
        : AppColor.primary;

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
