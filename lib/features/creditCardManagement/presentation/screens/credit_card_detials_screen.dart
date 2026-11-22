import 'package:expence_app/core/constants/date_constant.dart';
import 'package:expence_app/core/theme/app_color.dart';
import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/presentation/widgets/credit_card_billing_cycle_card.dart';
import 'package:expence_app/features/creditCardManagement/presentation/widgets/credit_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../provider/credit_card_payment_provider.dart';


class CreditCardDetailsScreen extends StatelessWidget {
  const CreditCardDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final creditCard = context
        .select<CreditCardDetailsProvider, CreditCardModel>(
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
              CreditCardWidget(
                creditCard: creditCard,
                palette: palette,
                currentUsage: currentCycle?.totalAmount ?? 0.0,
                onTap: () {},
                hasBillingCycle: currentCycle != null,
              ),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Current Billing Cycle'),
              const SizedBox(height: 12),
              currentCycle == null
                  ? _EmptyCycleNotice(
                      message: 'No active billing cycle yet for this card.',
                    )
                  : CreditCardBillingCycleCard(
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
                  child: CreditCardBillingCycleCard(
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
