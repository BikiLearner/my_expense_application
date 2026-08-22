import '../../../bank/data/model/bank_model.dart';
import 'billing_cycle_model.dart';
import 'credit_card.dart';

class CreditPaymentParams {
  final CreditCardModel creditCard;
  final BillingCycleModel billingCycle;
  final List<BankModel> banks;

  const CreditPaymentParams({
    required this.creditCard,
    required this.billingCycle,
    required this.banks,
  });
}
