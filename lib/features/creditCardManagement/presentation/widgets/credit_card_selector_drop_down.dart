import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_color.dart';

class CreditCardSelectorDropDown extends StatelessWidget {
  const CreditCardSelectorDropDown({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CreditExpenseProvider>(
      builder: (context, provider, child) {
        return DropdownButtonFormField<CreditCardModel>(
          value: provider.selectedCreditCard,
          isExpanded: true,

          // 1. FIX: Increase itemHeight to prevent vertical RenderFlex overflow in the menu
          itemHeight: 70,

          dropdownColor: AppColor.creditSurface,
          decoration: InputDecoration(
            labelText: 'Credit Card',
            labelStyle: TextStyle(color: AppColor.grey500),
            hintText: 'Select credit card',
            hintStyle: TextStyle(color: AppColor.grey700),
            prefixIcon: const Icon(
              Icons.credit_card_outlined,
              color: AppColor.creditAccent, // Premium gold accent
            ),
            filled: true,
            fillColor: AppColor.cardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16, // Adjusted for better balance
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

          // 2. FIX: Create a compact view for the selected item so it doesn't overflow the input box
          selectedItemBuilder: (BuildContext context) {
            return provider.creditCards.map<Widget>((CreditCardModel card) {
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
                    '₹${card.creditLimit.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColor.creditLimit,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList();
          },

          // 3. IMPROVEMENT: Polished Dropdown menu items
          items: provider.creditCards.map((card) {
            final palette = AppColor.paletteFor(card.creditCardId);

            return DropdownMenuItem<CreditCardModel>(
              value: card,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    // Styled Icon with dynamic background
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: palette.glow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: palette.accent.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.credit_card_rounded,
                        size: 22,
                        color: palette.accent,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Card & Bank Name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            card.cardName,
                            style: const TextStyle(
                              color: AppColor.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            card.bankName,
                            style: TextStyle(
                              color: AppColor.textSecondary.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Limit
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '₹${card.creditLimit.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Limit',
                          style: TextStyle(
                            color: AppColor.textSecondary.withOpacity(0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
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