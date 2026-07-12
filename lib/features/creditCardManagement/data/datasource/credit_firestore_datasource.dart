import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/core/constants/collection_name_constant.dart';

import '../../../../core/services/session_maganger.dart';
import '../model/credit_card_expense_item_model.dart';

class CreditFirestoreDatasource {
  CreditFirestoreDatasource._();

  static final CreditFirestoreDatasource instance =
      CreditFirestoreDatasource._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCreditExpense({
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    required String creditCardId,
    required DateTime purchaseDate,
    required String billingCycleId,
  }) async {
    final userRef = SessionManager.instance.userRef;

    final cardRef = userRef
        .collection(CollectionName.credit)
        .doc(CollectionName.credit)
        .collection(CollectionName.creditCards)
        .doc(creditCardId);

    final billingCycleRef = cardRef
        .collection(CollectionName.billingCycle)
        .doc(billingCycleId);

    final expenseRef = billingCycleRef
        .collection(CollectionName.creditExpenses)
        .doc();

    await _firestore.runTransaction((transaction) async {
      final cardSnapshot = await transaction.get(cardRef);

      if (!cardSnapshot.exists) {
        throw Exception('Credit card not found.');
      }

      final billingCycleSnapshot = await transaction.get(billingCycleRef);

      if (!billingCycleSnapshot.exists) {
        throw Exception('Billing cycle not found.');
      }

      final cardData = cardSnapshot.data()!;

      final creditLimit = (cardData['creditLimit'] as num?)?.toDouble() ?? 0.0;

      final currentUsed = (cardData['currentUsed'] as num?)?.toDouble() ?? 0.0;

      if (currentUsed + amount > creditLimit) {
        throw Exception('Credit limit exceeded.');
      }

      transaction.set(expenseRef, {
        'title': title,
        'amount': amount,
        'type': expenseTypeName,
        'description': description,
        'purchaseDate': Timestamp.fromDate(purchaseDate),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(cardRef, {
        'currentUsed': FieldValue.increment(amount),
      });

      transaction.update(billingCycleRef, {
        'totalAmount': FieldValue.increment(amount),
      });
    });
  }

  // Future<void> editCreditExpense();
  //
  // Future<void> deleteCreditExpense();
  //
  Stream<List<CreditExpenseItem>> watchCreditExpenses({
    required String creditCardId,
    required String billingCycleId,
    required DateTime selectedDate,
  }) {
    final userRef = SessionManager.instance.userRef;

    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final endOfDay = startOfDay.add(const Duration(days: 1));

    return userRef
        .collection(CollectionName.credit)
        .doc(CollectionName.credit)
        .collection(CollectionName.creditCards)
        .doc(creditCardId)
        .collection(CollectionName.billingCycle)
        .doc(billingCycleId)
        .collection(CollectionName.creditExpenses)
        .where(
          'purchaseDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('purchaseDate', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CreditExpenseItem.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  //
  // Future<List<CreditExpenseItem>> getExpensesByBillingCycle();
  //
  // Future<List<CreditExpenseItem>> getExpensesByCard();
}
