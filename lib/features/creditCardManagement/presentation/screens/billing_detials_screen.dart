import 'package:expence_app/core/constants/date_constant.dart';
import 'package:expence_app/core/theme/app_color.dart';
import 'package:expence_app/features/creditCardManagement/data/model/billing_cycle_model.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/credit_card_expense_item_model.dart';
import '../provider/credit_card_payment_provider.dart';
import '../widgets/credit_expense_item_tile.dart';

/// Shows every expense that belongs to a single billing cycle.
///
/// Used both for the *current* billing cycle (from the button on
/// [CreditCardDetailsScreen]) and for any cycle picked from the
/// billing-cycle history list. When [isCurrentCycle] is true expenses can
/// be deleted (swipe to remove) and a payment bar is shown at the bottom;
/// past cycles are read-only.
class BillingCycleDetailsScreen extends StatelessWidget {
  final CreditCardModel creditCard;
  final BillingCycleModel billingCycle;
  final bool isCurrentCycle;

  const BillingCycleDetailsScreen({
    super.key,
    required this.creditCard,
    required this.billingCycle,
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
      body: Column(
        children: [
          _header(),

          const SizedBox(height: 16),

          Expanded(child: _expenseList()),
        ],
      ),
    );
  }

  Widget _expenseList() {
    return Selector<CreditCardDetailsProvider, List<CreditExpenseItem>>(
      selector: (_, provider) => provider.creditCardExpenseByBillingCycle,
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
          padding: const EdgeInsets.fromLTRB(5, 0, 16, 16),
          itemCount: expenses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final expense = expenses[index];

            return CreditExpenseItemTile(expenseItem: expense, toShow: false);
          },
        );
      },
    );
  }

  Widget _header() {
    final statusColor = switch (billingCycle.status.toLowerCase()) {
      "paid" => AppColor.creditPaid,
      "active" => AppColor.creditEMI,
      _ => AppColor.creditLimit,
    };

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.creditGradientStart, AppColor.creditGradientEnd],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColor.creditBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "${DateConstants.ddMMMyyyy(billingCycle.startDate)}"
                      " - "
                      "${DateConstants.ddMMMyyyy(billingCycle.endDate)}",
                  style: TextStyle(color: AppColor.creditAccent.withOpacity(.7)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: statusColor.withOpacity(.4)),
                ),
                child: Text(
                  billingCycle.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            "₹${billingCycle.totalAmount.toStringAsFixed(0)}",
            style: const TextStyle(
              color: AppColor.creditAccent,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: .3,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _summaryTile(
                  "Needed",
                  billingCycle.needed ?? 0,
                  AppColor.creditLimit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryTile(
                  "Saving",
                  billingCycle.saving ?? 0,
                  AppColor.creditPaid,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryTile(
                  "Luxury",
                  billingCycle.luxury ?? 0,
                  AppColor.creditEMI,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Divider(color: AppColor.creditBorder, height: 1),

          const SizedBox(height: 16),

          _paymentButton(),
        ],
      ),
    );
  }

  Widget _summaryTile(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: AppColor.creditAccent.withOpacity(.6)),
          ),
          const SizedBox(height: 6),
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style: TextStyle(
              color: AppColor.creditAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Payment
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.creditAccent,
          foregroundColor: AppColor.creditDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          "Pay ₹${billingCycle.totalAmount.toStringAsFixed(0)}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: .3,
          ),
        ),
      ),
    );
  }
}