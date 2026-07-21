import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';

class CreditCardSelectorDropDown extends StatelessWidget {
  const CreditCardSelectorDropDown({super.key});

  /// Green when plenty of limit is left, amber when getting low,
  /// red when almost exhausted.
  Color _remainingColor(double used, double limit) {
    if (limit <= 0) return AppColor.textSecondary;
    final ratio = used / limit;
    if (ratio >= 0.85) return AppColor.creditDue; // red
    if (ratio >= 0.6) return AppColor.creditEMI; // amber
    return AppColor.creditPaid; // green
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CreditExpenseProvider>(
      builder: (context, provider, child) {
        return DropdownButtonFormField<CreditCardModel>(
          value: provider.selectedCreditCard,
          isExpanded: true,

          // Increased to fit the two-line item layout without overflow.
          itemHeight: 78,

          dropdownColor: AppColor.creditSurface,
          decoration: InputDecoration(
            labelText: 'Credit Card',
            labelStyle: TextStyle(color: AppColor.grey500),
            hintText: 'Select credit card',
            hintStyle: TextStyle(color: AppColor.grey700),
            prefixIcon: const Icon(
              Icons.credit_card_outlined,
              color: AppColor.creditAccent,
            ),
            filled: true,
            fillColor: AppColor.cardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColor.cardBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColor.creditAccent,
                width: 2,
              ),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColor.white,
          ),

          // Compact view for the selected item (collapsed field).
          selectedItemBuilder: (BuildContext context) {
            return provider.creditCards.map<Widget>((CreditCardModel card) {
              final used = provider.usedAmountForCard(card.creditCardId);
              final left = (card.creditLimit - used).clamp(
                0,
                card.creditLimit,
              );

              return Row(
                children: [
                  Expanded(
                    child: Text(
                      '${card.cardName} • ${card.bankName}',
                      style: const TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '₹${left.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: _remainingColor(used, card.creditLimit),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList();
          },

          // Dropdown menu items — each card visually distinct via its
          // deterministic palette (accent bar + tinted icon chip).
          items: provider.creditCards.map((card) {
            final palette = AppColor.paletteFor(card.creditCardId);
            final used = provider.usedAmountForCard(card.creditCardId);
            final left = (card.creditLimit - used).clamp(
              0,
              card.creditLimit,
            );
            final remainingColor = _remainingColor(used, card.creditLimit);

            return DropdownMenuItem<CreditCardModel>(
              value: card,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: palette.accent, width: 3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    children: [
                      // Tinted icon chip — distinguishes this card at a glance.
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.glow.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: palette.accent.withOpacity(0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.credit_card_rounded,
                          size: 20,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name + total left on one row, limit/bank below.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    card.cardName,
                                    style: const TextStyle(
                                      color: AppColor.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '₹${left.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: remainingColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${card.bankName} • Limit ₹${card.creditLimit.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppColor.textSecondary.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),

          onChanged: (card) {
            if (card != null) {
              provider.setSelectedCreditCard(card);
            }
          },
        );
      },
    );
  }
}