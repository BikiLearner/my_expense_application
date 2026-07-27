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
  DocumentReference<Map<String, dynamic>> _creditYearStatsRef({
    required String year,
  }) {
    return userReference
        .collection(CollectionName.creditYearlyStats)
        .doc(year);
  }

  DocumentReference<Map<String, dynamic>> _creditMonthStatsRef({
    required String year,
    required String monthId,
  }) {
    return _creditYearStatsRef(year: year)
        .collection(CollectionName.months)
        .doc(monthId);
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

    final year = purchaseDate.year.toString();

    final monthId =
        '${purchaseDate.year}-'
        '${purchaseDate.month.toString().padLeft(2, '0')}';

    final creditYearRef = _creditYearStatsRef(
      year: year,
    );

    final creditMonthRef = _creditMonthStatsRef(
      year: year,
      monthId: monthId,
    );


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
        expenseTypeName: FieldValue.increment(amount)
      });

      transaction.set(
        creditYearRef,
        {
          'year': year,
          'grandTotal': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

// Credit MONTH stats
      transaction.set(
        creditMonthRef,
        {
          'month': monthId,
          'grandTotal': FieldValue.increment(amount),
          expenseTypeName: FieldValue.increment(amount),
          'transactionCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint("it here going  : $expenseTypeName");
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
      // ---- READS (must happen before any writes) ----
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

      final billingSnapshot = await transaction.get(billingCycleRef);
      if (!billingSnapshot.exists) {
        throw Exception('Billing cycle not found.');
      }
      final billingCycle = BillingCycleModel.fromFirestore(
        billingSnapshot.id,
        billingSnapshot.data()!,
      );

      final oldType = oldExpense.type.name;
      final newType = expenseTypeName;
      final difference = amount - oldExpense.amount;

      final newTotal = billingCycle.totalAmount + difference;
      if (newTotal > card.creditLimit) {
        throw Exception('Credit limit exceeded.');
      }

      // Where the amount was originally counted
      final oldYear = oldExpense.purchaseDate.year.toString();
      final oldMonthId =
          '${oldExpense.purchaseDate.year}-'
          '${oldExpense.purchaseDate.month.toString().padLeft(2, '0')}';

      // Where it should be counted after the edit
      final newYear = purchaseDate.year.toString();
      final newMonthId =
          '${purchaseDate.year}-'
          '${purchaseDate.month.toString().padLeft(2, '0')}';

      final oldYearRef = _creditYearStatsRef(year: oldYear);
      final oldMonthRef = _creditMonthStatsRef(year: oldYear, monthId: oldMonthId);
      final newYearRef = _creditYearStatsRef(year: newYear);
      final newMonthRef = _creditMonthStatsRef(year: newYear, monthId: newMonthId);

      // ---- WRITES ----

      // Expense doc itself
      transaction.update(expenseRef, {
        'title': title,
        'amount': amount,
        'type': expenseTypeName,
        'description': description,
        'purchaseDate': Timestamp.fromDate(purchaseDate),
      });

      // Billing cycle totals
      if (oldType == newType) {
        transaction.update(billingCycleRef, {
          'totalAmount': FieldValue.increment(difference),
          newType: FieldValue.increment(difference),
        });
      } else {
        transaction.update(billingCycleRef, {
          'totalAmount': FieldValue.increment(difference),
          oldType: FieldValue.increment(-oldExpense.amount),
          newType: FieldValue.increment(amount),
        });
      }

      // Year / month stats
      if (oldYear == newYear && oldMonthId == newMonthId) {
        // Same month — adjust in place
        transaction.set(
          newYearRef,
          {
            'grandTotal': FieldValue.increment(difference),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        if (oldType == newType) {
          transaction.set(
            newMonthRef,
            {
              'grandTotal': FieldValue.increment(difference),
              newType: FieldValue.increment(difference),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        } else {
          transaction.set(
            newMonthRef,
            {
              'grandTotal': FieldValue.increment(difference),
              oldType: FieldValue.increment(-oldExpense.amount),
              newType: FieldValue.increment(amount),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      } else {
        // Purchase date moved to a different month/year — migrate the stats
        transaction.set(
          oldYearRef,
          {
            'grandTotal': FieldValue.increment(-oldExpense.amount),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        transaction.set(
          oldMonthRef,
          {
            'grandTotal': FieldValue.increment(-oldExpense.amount),
            oldType: FieldValue.increment(-oldExpense.amount),
            'transactionCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        transaction.set(
          newYearRef,
          {
            'year': newYear,
            'grandTotal': FieldValue.increment(amount),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        transaction.set(
          newMonthRef,
          {
            'month': newMonthId,
            'grandTotal': FieldValue.increment(amount),
            newType: FieldValue.increment(amount),
            'transactionCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
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

      // Use the same key consistently for both billing cycle and month stats
      final expenseTypeName = expense.type.name;

      // Calendar year/month comes from the actual purchase date
      final year = expense.purchaseDate.year.toString();
      final monthId =
          '${expense.purchaseDate.year}-'
          '${expense.purchaseDate.month.toString().padLeft(2, '0')}';

      final creditYearRef = _creditYearStatsRef(year: year);
      final creditMonthRef = _creditMonthStatsRef(year: year, monthId: monthId);

      // Billing cycle
      transaction.update(billingCycleRef, {
        'totalAmount': FieldValue.increment(-expense.amount),
        expenseTypeName: FieldValue.increment(-expense.amount),
      });

      // Year stats
      transaction.set(
        creditYearRef,
        {
          'grandTotal': FieldValue.increment(-expense.amount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Month stats
      transaction.set(
        creditMonthRef,
        {
          'grandTotal': FieldValue.increment(-expense.amount),
          expenseTypeName: FieldValue.increment(-expense.amount),
          'transactionCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Delete actual expense
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
