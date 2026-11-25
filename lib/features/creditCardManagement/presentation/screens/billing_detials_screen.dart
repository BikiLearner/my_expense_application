import 'package:expence_app/core/constants/date_constant.dart';
import 'package:expence_app/core/theme/app_color.dart';
import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:expence_app/features/creditCardManagement/presentation/widgets/credit_card_billing_cycle_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';
import '../../data/model/credit_card_expense_item_model.dart';
import '../provider/credit_card_payment_provider.dart';
import '../widgets/credit_expense_item_tile.dart';

class BillingCycleDetailsScreen extends StatelessWidget {
  final CreditCardModel creditCard;
  final bool isCurrentCycle;

  const BillingCycleDetailsScreen({
    super.key,
    required this.creditCard,
    required this.isCurrentCycle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.creditSurface,
      appBar: AppBar(
        backgroundColor: AppColor.creditSurface,
        elevation: 0,
        foregroundColor: AppColor.creditAccent,
        title: Text(
          isCurrentCycle ? "Current Billing Cycle" : "Billing Cycle",
          style: const TextStyle(
            color: AppColor.creditAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Selector<CreditExpenseProvider, BillingCycleModel?>(
        selector: (_, provider) =>
            provider.getCycleById(creditCard.creditCardId ?? ''),
        builder: (context, billingCycle, _) {
          if (billingCycle == null || (billingCycle.isPaid ?? false)) {
            return const SizedBox.shrink();
          }
          return _payFab(context, billingCycle);
        },
      ),
      body: Selector<CreditExpenseProvider, BillingCycleModel?>(
        selector: (_, provider) =>
            provider.getCycleById(creditCard.creditCardId ?? ''),
        builder: (context, billingCycle, _) {
          if (billingCycle == null) {
            return const Center(
              child: Text("No billing cycle details available"),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: CreditCardBillingCycleCard(
                  billingCycle: billingCycle,
                  accent: AppColor.creditAccent,
                  onTap: () {},
                  showButton: false,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(child: _expenseList(billingCycle)),
            ],
          );
        },
      ),
    );
  }

  Widget _expenseList(BillingCycleModel billingCycle) {
    return Selector<CreditCardDetailsProvider, List<CreditExpenseItem>>(
      selector: (_, provider) =>
          provider.getBillingCycleItemsById(billingCycle.billingCycleId),
      builder: (context, expenses, _) {
        if (expenses.isEmpty) {
          return Center(
            child: Text(
              "No expenses found",
              style: TextStyle(
                color: AppColor.creditAccent.withOpacity(.5),
                fontSize: 15,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final expense = expenses[index];

            return CreditExpenseItemTile(
              expenseItem: expense,
              toShow: true,
              creditCardId: creditCard.creditCardId,
              billingCycleId: billingCycle.billingCycleId,
            );
          },
        );
      },
    );
  }

  Widget _payFab(BuildContext context, BillingCycleModel billingCycle) {
    return FloatingActionButton.extended(
      onPressed: () {
        context.push(
          AppRoutes.creditPayment,
          extra: (
          context.read<CreditCardDetailsProvider>(),
          creditCard,
          billingCycle,
          isCurrentCycle,
          ),
        );
      },
      backgroundColor: AppColor.creditAccent,
      foregroundColor: AppColor.creditDark,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      icon: const Icon(Icons.payments_rounded),
      label: Text(
        'Pay ₹${billingCycle.totalAmount.toStringAsFixed(0)}',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

}
