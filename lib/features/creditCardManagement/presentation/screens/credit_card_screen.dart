import 'package:expence_app/core/theme/app_color.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:expence_app/features/creditCardManagement/presentation/provider/credit_expense_provider.dart';
import 'package:expence_app/features/creditCardManagement/presentation/screens/credit_card_from_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CreditCardScreen extends StatefulWidget {
  const CreditCardScreen({super.key});

  @override
  State<CreditCardScreen> createState() => _CreditCardScreenState();
}

class _CreditCardScreenState extends State<CreditCardScreen> {
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
            MaterialPageRoute(
              builder: (_) => const CreditCardFromPage(),
            ),
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
              child: CircularProgressIndicator(
                color: AppColor.creditAccent,
              ),
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
                      Icon(Icons.account_balance_wallet_rounded,
                          size: 14, color: AppColor.creditAccent.withOpacity(.9)),
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
                    '₹${totalCreditLimit.toStringAsFixed(2)}',
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
              final palette =
              AppColor.paletteFor(card.bankName + card.cardName);
              return _CreditCard(creditCard: card, palette: palette);
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

// 🎴 Premium Bank Card
class _CreditCard extends StatelessWidget {
  final CreditCardModel creditCard;
  final CreditCardPalette palette;

  const _CreditCard({
    required this.creditCard,
    required this.palette,
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
        border: Border.all(
          color: Colors.white.withOpacity(.08),
          width: 1,
        ),
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
          onTap: () {
            // TODO: Navigate to details
          },
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
                      "₹ ${creditCard.creditLimit.toStringAsFixed(0)}",
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
                            label: "Statement",
                            value: "${creditCard.statementDay}",
                            accent: palette.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoChip(
                            icon: Icons.event_rounded,
                            label: "Due Date",
                            value: "${creditCard.dueDay}",
                            accent: palette.accent,
                          ),
                        ),
                      ],
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

// 🟢 Active / Inactive pill
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

// 📊 Info Chip Widget
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
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: accent.withOpacity(.85),
                ),
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