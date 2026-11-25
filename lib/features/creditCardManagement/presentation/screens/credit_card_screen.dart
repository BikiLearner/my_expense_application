import 'package:expence_app/core/theme/app_color.dart';
import 'package:expence_app/core/utils/compact_number_formatter.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:expence_app/features/creditCardManagement/presentation/screens/credit_card_from_page.dart';
import 'package:expence_app/features/creditCardManagement/presentation/widgets/credit_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/app_routes.dart';

class CreditCardScreen extends StatelessWidget {
  const CreditCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.creditSurface,
      appBar: AppBar(
        backgroundColor: AppColor.creditSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.creditAccent.withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: AppColor.creditAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'My Credit Cards',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColor.creditAccent,
        foregroundColor: AppColor.creditDark,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreditCardFromPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Credit Card',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Selector<CreditExpenseProvider, _BankListState>(
        selector: (_, provider) =>
            _BankListState(provider.isLoading, provider.creditCards),
        builder: (context, state, _) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColor.creditAccent),
            );
          }

          if (state.creditCards.isEmpty) {
            return _buildEmptyState();
          }

          return _buildCreditCardList(state.creditCards);
        },
      ),
    );
  }

  // 🎨 Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.creditAccent.withOpacity(.08),
              ),
              child: Icon(
                Icons.credit_card_off_rounded,
                size: 56,
                color: AppColor.creditAccent.withOpacity(.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Credit Cards Added',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first credit card and start tracking your spending.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardList(List<CreditCardModel> creditCards) {
    final totalCreditLimit = creditCards.fold<double>(
      0,
      (sum, card) => sum + card.creditLimit,
    );

    return Column(
      children: [
        // 💳 Total Credit Limit Banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                AppColor.creditGradientStart,
                AppColor.creditGradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColor.creditBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColor.creditGradientStart.withOpacity(.5),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 14,
                        color: AppColor.creditAccent.withOpacity(.9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TOTAL CREDIT LIMIT',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: .8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${CompactNumberFormatter.format(totalCreditLimit)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColor.creditAccent.withOpacity(.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColor.creditAccent.withOpacity(.35),
                  ),
                ),
                child: Text(
                  '${creditCards.length} ${creditCards.length == 1 ? 'Card' : 'Cards'}',
                  style: const TextStyle(
                    color: AppColor.creditAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 💳 Credit Card List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: creditCards.length,
            itemBuilder: (_, index) {
              final card = creditCards[index];
              final palette = AppColor.paletteFor(
                card.bankName + card.cardName,
              );
              return Selector<CreditExpenseProvider, double?>(
                selector: (_, provider) =>
                    provider.getCycleAmountById(card.creditCardId),
                builder: (context, currentUsage, child) {
                  return CreditCardWidget(
                    creditCard: card,
                    palette: palette,
                    currentUsage: currentUsage,
                    onTap: () {
                      context.push(AppRoutes.creditDetails, extra: card);
                    },
                    hasBillingCycle: currentUsage != null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BankListState {
  final bool isLoading;
  final List<CreditCardModel> creditCards;

  const _BankListState(this.isLoading, this.creditCards);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BankListState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          creditCards == other.creditCards;

  @override
  int get hashCode => isLoading.hashCode ^ creditCards.hashCode;
}
