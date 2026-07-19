import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expence_app/core/constants/collection_name_constant.dart';
import 'package:expence_app/features/creditCardManagement/data/model/credit_card.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/services/session_maganger.dart';
import '../model/billing_cycle_model.dart';
import '../model/credit_card_expense_item_model.dart';

class CreditFirestoreDatasource {
  CreditFirestoreDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference userReference = SessionManager.instance.userRef;

  // all reference generator methods
  CollectionReference<Map<String, dynamic>> _creditCardCollection() {
    return userReference.collection(CollectionName.creditCards);
  }

  DocumentReference<Map<String, dynamic>> _creditCardRef({
    String? creditCardId,
  }) => userReference.collection(CollectionName.creditCards).doc(creditCardId);

  DocumentReference<Map<String, dynamic>> _billingCycleRef({
    String? creditCardId,
    String? billingCycleId,
  }) => userReference
      .collection(CollectionName.creditCards)
      .doc(creditCardId)
      .collection(CollectionName.billingCycle)
      .doc(billingCycleId);

  Future<void> addCreditExpense({
    required CreditCardModel card,
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    required DateTime purchaseDate,
  }) async {
    final cardRef = _creditCardRef(creditCardId: card.creditCardId);

    await _firestore.runTransaction((transaction) async {
      final cardSnapshot = await transaction.get(cardRef);
      if (!cardSnapshot.exists) {
        throw Exception('Credit card not found.');
      }
      final cardData = CreditCardModel.fromFirestore(
        cardSnapshot.id,
        cardSnapshot.data()!,
      );
      final creditLimit = cardData.creditLimit;

      final billingCycle = BillingCycleModel.calculate(
        statementDay: card.statementDay,
        expenseDate: purchaseDate,
      );

      final billingCycleRef = _billingCycleRef(
        creditCardId: card.creditCardId,
        billingCycleId: billingCycle.billingCycleId,
      );

      final billingSnapshot = await transaction.get(billingCycleRef);
      double currentUsed = 0;

      if (billingSnapshot.exists) {
        final existingCycle = BillingCycleModel.fromFirestore(
          billingSnapshot.id,
          billingSnapshot.data()!,
        );

        currentUsed = existingCycle.totalAmount;
      } else {
        transaction.set(billingCycleRef, billingCycle.toFirestore());
        if (cardData.currentBillingCycleId != billingCycle.billingCycleId) {
          transaction.update(cardRef, {
            'currentBillingCycleId': billingCycle.billingCycleId,
          });
        }
      }

      if (currentUsed + amount > creditLimit) {
        throw Exception('Credit limit exceeded.');
      }

      final expenseRef = billingCycleRef
          .collection(CollectionName.creditExpenses)
          .doc();

      transaction.set(expenseRef, {
        'id':expenseRef.id,
        'title': title,
        'amount': amount,
        'type': expenseTypeName,
        'description': description,
        'purchaseDate': Timestamp.fromDate(purchaseDate),
        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.update(billingCycleRef, {
        'totalAmount': FieldValue.increment(amount),
      });
    });
  }
  Stream<List<CreditExpenseItem>> watchCreditExpenses({
    required String creditCardId,
    required String billingCycleId,
  }) {
    return _billingCycleRef(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
    )
        .collection(CollectionName.creditExpenses)
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => CreditExpenseItem.fromFirestore(
          doc.id,
          doc.data(),
        ),
      )
          .toList(),
    );
  }

  Stream<List<CreditExpenseItem>> watchCreditExpensesByDate({
    required String creditCardId,
    required String billingCycleId,
    required DateTime selectedDate,
  }) {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _billingCycleRef(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
    )
        .collection(CollectionName.creditExpenses)
        .where(
      'purchaseDate',
      isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
    )
        .where(
      'purchaseDate',
      isLessThan: Timestamp.fromDate(endOfDay),
    )
        .orderBy('purchaseDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => CreditExpenseItem.fromFirestore(
          doc.id,
          doc.data(),
        ),
      )
          .toList(),
    );
  }
  Future<void> editCreditExpense({
    required String creditCardId,
    required String billingCycleId,
    required String expenseId,
    required String title,
    required double amount,
    required String description,
    required String expenseTypeName,
    required DateTime purchaseDate,
  }) async {
    final cardRef = _creditCardRef(creditCardId: creditCardId);

    final billingCycleRef = _billingCycleRef(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
    );

    final expenseRef = billingCycleRef
        .collection(CollectionName.creditExpenses)
        .doc(expenseId);

    await _firestore.runTransaction((transaction) async {
      final cardSnapshot = await transaction.get(cardRef);
      if (!cardSnapshot.exists) {
        throw Exception('Credit card not found.');
      }

      final card = CreditCardModel.fromFirestore(
        cardSnapshot.id,
        cardSnapshot.data()!,
      );

      final expenseSnapshot = await transaction.get(expenseRef);
      if (!expenseSnapshot.exists) {
        throw Exception('Expense not found.');
      }

      final oldExpense = CreditExpenseItem.fromFirestore(
        expenseSnapshot.id,
        expenseSnapshot.data()!,
      );

      final difference = amount - oldExpense.amount;

      final billingSnapshot = await transaction.get(billingCycleRef);
      if (!billingSnapshot.exists) {
        throw Exception('Billing cycle not found.');
      }

      final billingCycle = BillingCycleModel.fromFirestore(
        billingSnapshot.id,
        billingSnapshot.data()!,
      );

      final newTotal = billingCycle.totalAmount + difference;

      if (newTotal > card.creditLimit) {
        throw Exception('Credit limit exceeded.');
      }

      transaction.update(expenseRef, {
        'title': title,
        'amount': amount,
        'type': expenseTypeName,
        'description': description,
        'purchaseDate': Timestamp.fromDate(purchaseDate),
      });

      if (difference != 0) {
        transaction.update(billingCycleRef, {
          'totalAmount': FieldValue.increment(difference),
        });
      }
    });
  }
  Future<void> deleteCreditExpense({
    required String creditCardId,
    required String billingCycleId,
    required String expenseId,
  }) async {
    final billingCycleRef = _billingCycleRef(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
    );

    final expenseRef = billingCycleRef
        .collection(CollectionName.creditExpenses)
        .doc(expenseId);

    await _firestore.runTransaction((transaction) async {
      final expenseSnapshot = await transaction.get(expenseRef);

      if (!expenseSnapshot.exists) {
        throw Exception('Expense not found.');
      }

      final expense = CreditExpenseItem.fromFirestore(
        expenseSnapshot.id,
        expenseSnapshot.data()!,
      );

      final billingSnapshot = await transaction.get(billingCycleRef);

      if (!billingSnapshot.exists) {
        throw Exception('Billing cycle not found.');
      }

      transaction.update(billingCycleRef, {
        'totalAmount': FieldValue.increment(-expense.amount),
      });

      transaction.delete(expenseRef);
    });
  }
  Future<void> createCreditCard({
    required String cardName,
    required String bankName,
    required double creditLimit,
    required int statementDay,
    required int dueDay,
  }) async {
    try {
      final docRef = _creditCardCollection().doc();

      final creditCardModel = CreditCardModel(
        creditCardId: docRef.id,
        cardName: cardName,
        bankName: bankName,
        creditLimit: creditLimit,
        statementDay: statementDay,
        dueDay: dueDay,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await docRef.set(creditCardModel.toFirestore());
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Error creating credit card: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<CreditCardModel>> fetchCreditCards() async {
    try {
      final snapshot = await _creditCardCollection().get();

      return snapshot.docs
          .map((doc) => CreditCardModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Error fetching credit cards: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateCreditCard() {
    // TODO: implement updateCreditCard
    throw UnimplementedError();
  }

  Future<BillingCycleModel> createBillingCycleIfNeeded(
    CreditCardModel card,
    DateTime expenseDate,
  ) async {
    final billingCycle = BillingCycleModel.calculate(
      statementDay: card.statementDay,
      expenseDate: expenseDate,
    );

    final billingCycleRef = _billingCycleRef(
      creditCardId: card.creditCardId,
      billingCycleId: billingCycle.billingCycleId,
    );

    final snapshot = await billingCycleRef.get();

    // Billing cycle already exists
    if (snapshot.exists) {
      // Ensure the card points to the current billing cycle
      if (card.currentBillingCycleId != billingCycle.billingCycleId) {
        await _creditCardRef(
          creditCardId: card.creditCardId,
        ).update({'currentBillingCycleId': billingCycle.billingCycleId});
      }

      return BillingCycleModel.fromFirestore(snapshot.id, snapshot.data()!);
    }

    // Create the billing cycle and update the card atomically
    final batch = _firestore.batch();

    batch.set(billingCycleRef, billingCycle.toFirestore());

    batch.update(_creditCardRef(creditCardId: card.creditCardId), {
      'currentBillingCycleId': billingCycle.billingCycleId,
    });

    await batch.commit();

    return billingCycle;
  }

  Stream<BillingCycleModel?> watchBillingCycle({
    required String creditCardId,
    required String billingCycleId,
  }) {
    return _billingCycleRef(
      creditCardId: creditCardId,
      billingCycleId: billingCycleId,
    ).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }

      return BillingCycleModel.fromFirestore(snapshot.id, snapshot.data()!);
    });
  }
}
