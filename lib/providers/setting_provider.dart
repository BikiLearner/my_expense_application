import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class SettingsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // 🔹 Loading states
  bool _isCreatingBackup = false;
  bool _isRestoring = false;
  bool _isRepairing = false;
  bool _isVerifying = false;

  bool get isCreatingBackup => _isCreatingBackup;
  bool get isRestoring => _isRestoring;
  bool get isRepairing => _isRepairing;
  bool get isVerifying => _isVerifying;

  // 🔹 Available backups cache
  List<BackupMetadata> _backups = [];
  List<BackupMetadata> get backups => _backups;

  // ═══════════════════════════════════════════════════════════════
  // 🛡️ BACKUP FUNCTIONALITY
  // ═══════════════════════════════════════════════════════════════

  /// 📦 Create a new backup before destructive operations
  Future<String?> createBackup({
    required String reason,
    String? customName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    _isCreatingBackup = true;
    notifyListeners();

    try {
      final userRef = _firestore.collection('users').doc(uid);
      final backupRef = userRef.collection('backups').doc();
      final backupId = backupRef.id;

      if (kDebugMode) {
        print("📦 Creating backup: $backupId");
        print("   Reason: $reason");
      }

      // 1️⃣ Get current summary data (cheap reads)
      final userDoc = await userRef.get();
      final grandTotal = (userDoc.data()?['grandTotal'] as num?)?.toDouble() ?? 0;

      // 2️⃣ Verify data integrity before backup
      final integrity = await verifyDataIntegrity();

      // 3️⃣ Count items and dates
      final expensesSnap = await userRef.collection('expenses').get();
      int totalDates = expensesSnap.docs.length;
      int totalItems = 0;

      for (final dateDoc in expensesSnap.docs) {
        final itemsSnap = await dateDoc.reference.collection('items').get();
        totalItems += itemsSnap.docs.length;
      }

      // 4️⃣ Write backup metadata
      await backupRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'manual',
        'reason': reason,
        'customName': customName,
        'summary': {
          'totalDates': totalDates,
          'totalItems': totalItems,
          'grandTotal': grandTotal,
        },
        'integrity': {
          'verified': integrity['success'] ?? false,
          'issuesFound': integrity['issuesFound'] ?? 0,
          'checkedDates': integrity['checkedDates'] ?? 0,
        },
        'version': 1,
        'appVersion': '1.0.0', // TODO: Replace with actual app version
      });

      // 5️⃣ Backup actual data in chunks
      await _backupExpensesChunks(backupRef);
      await _backupYearStatsChunks(backupRef);

      if (kDebugMode) {
        print("✅ Backup created successfully: $backupId");
        print("   Total items backed up: $totalItems");
        print("   Total dates backed up: $totalDates");
      }

      // Refresh backup list
      await fetchBackups();

      _isCreatingBackup = false;
      notifyListeners();

      return backupId;
    } catch (e) {
      debugPrint("❌ Backup creation failed: $e");
      _isCreatingBackup = false;
      notifyListeners();
      return null;
    }
  }

  /// 🧩 Backup expenses data in chunks (to avoid 1MB doc limit)
  Future<void> _backupExpensesChunks(DocumentReference backupRef) async {
    try {
      final expensesSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .get();

      const chunkSize = 10; // 10 dates per chunk
      int chunkIndex = 0;
      List<Map<String, dynamic>> buffer = [];

      for (final dateDoc in expensesSnap.docs) {
        final dateId = dateDoc.id;
        final dateData = dateDoc.data();

        // Get all items for this date
        final itemsSnap = await dateDoc.reference.collection('items').get();

        buffer.add({
          'dateId': dateId,
          'dateTotal': dateData['total'] ?? 0,
          'items': itemsSnap.docs.map((item) {
            final data = item.data();
            return {
              'id': item.id,
              'title': data['title'],
              'amount': data['amount'],
              'description': data['description'],
              'type': data['type'],
              'createdAt': data['createdAt'],
            };
          }).toList(),
        });

        // Write chunk when buffer is full
        if (buffer.length >= chunkSize) {
          await backupRef.collection('expense_chunks').doc('chunk_$chunkIndex').set({
            'index': chunkIndex,
            'count': buffer.length,
            'data': buffer,
          });

          if (kDebugMode) {
            print("   📦 Wrote expense chunk $chunkIndex (${buffer.length} dates)");
          }

          buffer.clear();
          chunkIndex++;
        }
      }

      // Write remaining data
      if (buffer.isNotEmpty) {
        await backupRef.collection('expense_chunks').doc('chunk_$chunkIndex').set({
          'index': chunkIndex,
          'count': buffer.length,
          'data': buffer,
        });

        if (kDebugMode) {
          print("   📦 Wrote final expense chunk $chunkIndex (${buffer.length} dates)");
        }
      }
    } catch (e) {
      debugPrint("❌ Failed to backup expense chunks: $e");
      rethrow;
    }
  }

  /// 🧩 Backup year stats in chunks
  Future<void> _backupYearStatsChunks(DocumentReference backupRef) async {
    try {
      final yearStatsSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('year_stats')
          .get();

      for (final yearDoc in yearStatsSnap.docs) {
        final year = yearDoc.id;
        final yearData = yearDoc.data();

        // Get all months for this year
        final monthsSnap = await yearDoc.reference.collection('months').get();

        await backupRef.collection('year_stats').doc(year).set({
          'year': year,
          'grandTotal': yearData['grandTotal'] ?? 0,
          'months': monthsSnap.docs.map((monthDoc) {
            final data = monthDoc.data();
            return {
              'month': monthDoc.id,
              'saving': data['saving'] ?? 0,
              'needed': data['needed'] ?? 0,
              'luxury': data['luxury'] ?? 0,
              'grandTotal': data['grandTotal'] ?? 0,
            };
          }).toList(),
        });

        if (kDebugMode) {
          print("   📦 Backed up year stats for $year");
        }
      }
    } catch (e) {
      debugPrint("❌ Failed to backup year stats: $e");
      rethrow;
    }
  }

  /// 📋 Fetch all available backups
  Future<void> fetchBackups() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .orderBy('createdAt', descending: true)
          .get();

      _backups = snapshot.docs.map((doc) {
        final data = doc.data();
        return BackupMetadata(
          id: doc.id,
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          reason: data['reason'] ?? 'Unknown',
          customName: data['customName'],
          totalItems: data['summary']?['totalItems'] ?? 0,
          totalDates: data['summary']?['totalDates'] ?? 0,
          grandTotal: (data['summary']?['grandTotal'] as num?)?.toDouble() ?? 0,
          issuesFound: data['integrity']?['issuesFound'] ?? 0,
        );
      }).toList();

      if (kDebugMode) {
        print("📋 Fetched ${_backups.length} backups");
      }

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Failed to fetch backups: $e");
    }
  }

  /// ♻️ Restore from backup
  Future<bool> restoreFromBackup({
    required String backupId,
    bool fullRestore = true,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    _isRestoring = true;
    notifyListeners();

    try {
      if (kDebugMode) {
        print("♻️ Starting restore from backup: $backupId");
        print("   Mode: ${fullRestore ? 'FULL' : 'PARTIAL'}");
      }

      final userRef = _firestore.collection('users').doc(uid);
      final backupRef = userRef.collection('backups').doc(backupId);

      // 1️⃣ Create a backup of current state before restoring
      await createBackup(reason: 'Before restore from $backupId');

      if (fullRestore) {
        // 2️⃣ Clear existing data
        await _clearAllExpenseData();

        // 3️⃣ Restore expense chunks
        await _restoreExpenseChunks(backupRef);

        // 4️⃣ Restore year stats
        await _restoreYearStats(backupRef);
      }

      if (kDebugMode) {
        print("✅ Restore completed successfully");
      }

      _isRestoring = false;
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint("❌ Restore failed: $e");
      _isRestoring = false;
      notifyListeners();
      return false;
    }
  }

  /// 🗑️ Clear all expense data (use with caution!)
  Future<void> _clearAllExpenseData() async {
    if (kDebugMode) {
      print("🗑️ Clearing all expense data...");
    }

    final userRef = _firestore.collection('users').doc(uid);

    // Delete all expense dates and items
    final expensesSnap = await userRef.collection('expenses').get();

    WriteBatch batch = _firestore.batch();
    int batchCount = 0;

    for (final dateDoc in expensesSnap.docs) {
      // Delete items
      final itemsSnap = await dateDoc.reference.collection('items').get();
      for (final item in itemsSnap.docs) {
        batch.delete(item.reference);
        batchCount++;

        if (batchCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Delete date doc
      batch.delete(dateDoc.reference);
      batchCount++;

      if (batchCount >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
    }

    // Delete year stats
    final yearStatsSnap = await userRef.collection('year_stats').get();
    for (final yearDoc in yearStatsSnap.docs) {
      // Delete months
      final monthsSnap = await yearDoc.reference.collection('months').get();
      for (final month in monthsSnap.docs) {
        batch.delete(month.reference);
        batchCount++;

        if (batchCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Delete year doc
      batch.delete(yearDoc.reference);
      batchCount++;

      if (batchCount >= 450) {
        await batch.commit();
        batch = _firestore.batch();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    if (kDebugMode) {
      print("✅ All expense data cleared");
    }
  }

  /// 📥 Restore expense chunks from backup
  Future<void> _restoreExpenseChunks(DocumentReference backupRef) async {
    if (kDebugMode) {
      print("📥 Restoring expense chunks...");
    }

    final chunksSnap = await backupRef.collection('expense_chunks').get();

    WriteBatch batch = _firestore.batch();
    int batchCount = 0;

    for (final chunk in chunksSnap.docs) {
      final data = chunk.data();
      final List<dynamic> dates = data['data'] ?? [];

      for (final dateData in dates) {
        final dateId = dateData['dateId'];
        final dateTotal = dateData['dateTotal'];
        final items = dateData['items'] as List<dynamic>;

        final userRef = _firestore.collection('users').doc(uid);
        final dateRef = userRef.collection('expenses').doc(dateId);

        // Restore date document
        batch.set(dateRef, {
          'date': dateId,
          'total': dateTotal,
          'restoredAt': FieldValue.serverTimestamp(),
        });

        batchCount++;

        // Restore items
        for (final itemData in items) {
          final itemRef = dateRef.collection('items').doc();
          batch.set(itemRef, {
            'title': itemData['title'],
            'amount': itemData['amount'],
            'description': itemData['description'],
            'type': itemData['type'],
            'createdAt': itemData['createdAt'],
          });

          batchCount++;

          if (batchCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    if (kDebugMode) {
      print("✅ Expense chunks restored");
    }
  }

  /// 📥 Restore year stats from backup
  Future<void> _restoreYearStats(DocumentReference backupRef) async {
    if (kDebugMode) {
      print("📥 Restoring year stats...");
    }

    final yearStatsSnap = await backupRef.collection('year_stats').get();

    WriteBatch batch = _firestore.batch();
    int batchCount = 0;

    for (final yearDoc in yearStatsSnap.docs) {
      final data = yearDoc.data();
      final year = data['year'];
      final grandTotal = data['grandTotal'];
      final months = data['months'] as List<dynamic>;

      final userRef = _firestore.collection('users').doc(uid);
      final yearRef = userRef.collection('year_stats').doc(year);

      // Restore year document
      batch.set(yearRef, {
        'grandTotal': grandTotal,
        'restoredAt': FieldValue.serverTimestamp(),
      });

      batchCount++;

      // Restore months
      for (final monthData in months) {
        final monthRef = yearRef.collection('months').doc(monthData['month']);
        batch.set(monthRef, {
          'month': monthData['month'],
          'saving': monthData['saving'],
          'needed': monthData['needed'],
          'luxury': monthData['luxury'],
          'grandTotal': monthData['grandTotal'],
          'restoredAt': FieldValue.serverTimestamp(),
        });

        batchCount++;

        if (batchCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    if (kDebugMode) {
      print("✅ Year stats restored");
    }
  }

  /// 🗑️ Delete a backup
  Future<bool> deleteBackup(String backupId) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final backupRef = userRef.collection('backups').doc(backupId);

      WriteBatch batch = _firestore.batch();

      // Delete expense chunks
      final expenseChunks = await backupRef.collection('expense_chunks').get();
      for (final chunk in expenseChunks.docs) {
        batch.delete(chunk.reference);
      }

      // Delete year stats
      final yearStats = await backupRef.collection('year_stats').get();
      for (final year in yearStats.docs) {
        batch.delete(year.reference);
      }

      // Delete backup document
      batch.delete(backupRef);

      await batch.commit();

      if (kDebugMode) {
        print("🗑️ Deleted backup: $backupId");
      }

      // Refresh backup list
      await fetchBackups();

      return true;
    } catch (e) {
      debugPrint("❌ Failed to delete backup: $e");
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 🔧 DATA REPAIR FUNCTIONALITY
  // ═══════════════════════════════════════════════════════════════

  /// 🔧 Recalculate and fix all totals based on actual expense items
  Future<Map<String, dynamic>> repairAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'success': false, 'error': 'No user'};

    _isRepairing = true;
    notifyListeners();

    final userRef = _firestore.collection('users').doc(uid);

    try {
      if (kDebugMode) {
        print("🔧 Starting data repair...");
      }

      // Create backup before repair
      await createBackup(reason: 'Before data repair');

      // Step 1: Get all expense dates
      final expenseDatesSnap = await userRef.collection('expenses').get();

      // Storage for calculations
      final Map<String, double> dateTotals = {};
      final Map<String, Map<String, Map<String, double>>> yearMonthStats = {};

      double overallGrandTotal = 0;
      int totalItems = 0;

      // Step 2: Read all items and calculate correct totals
      for (final dateDoc in expenseDatesSnap.docs) {
        final dateId = dateDoc.id;
        final dateRef = userRef.collection('expenses').doc(dateId);

        final itemsSnap = await dateRef.collection('items').get();

        double dayTotal = 0;

        for (final item in itemsSnap.docs) {
          final data = item.data();
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          final type = data['type'] as String? ?? 'luxury';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          if (amount <= 0) continue;

          dayTotal += amount;
          totalItems++;

          DateTime date;
          if (createdAt != null) {
            date = createdAt;
          } else {
            try {
              date = DateFormat('yyyy-MM-dd').parse(dateId);
            } catch (e) {
              if (kDebugMode) {
                print("⚠️ Skipping invalid dateId: $dateId");
              }
              continue;
            }
          }

          final year = DateFormat('yyyy').format(date);
          final month = DateFormat('yyyy-MM').format(date);

          yearMonthStats.putIfAbsent(year, () => {});
          yearMonthStats[year]!.putIfAbsent(month, () => {
            'saving': 0,
            'needed': 0,
            'luxury': 0,
            'grandTotal': 0,
          });

          yearMonthStats[year]![month]![type] =
              (yearMonthStats[year]![month]![type] ?? 0) + amount;
          yearMonthStats[year]![month]!['grandTotal'] =
              (yearMonthStats[year]![month]!['grandTotal'] ?? 0) + amount;
        }

        dateTotals[dateId] = dayTotal;
        overallGrandTotal += dayTotal;
      }

      if (kDebugMode) {
        print("📊 Calculated totals:");
        print("   Total items: $totalItems");
        print("   Total dates: ${dateTotals.length}");
        print("   Grand total: ₹$overallGrandTotal");
      }

      // Step 3: Write corrected data using batches
      int batchCount = 0;
      WriteBatch batch = _firestore.batch();

      // Update date totals
      for (final entry in dateTotals.entries) {
        final dateId = entry.key;
        final total = entry.value;

        batch.set(
          userRef.collection('expenses').doc(dateId),
          {
            'date': dateId,
            'total': total,
            'repairedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        batchCount++;
        if (batchCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Update year and month stats
      for (final yearEntry in yearMonthStats.entries) {
        final year = yearEntry.key;
        final months = yearEntry.value;

        double yearTotal = 0;
        for (final monthData in months.values) {
          yearTotal += monthData['grandTotal'] ?? 0;
        }

        batch.set(
          userRef.collection('year_stats').doc(year),
          {
            'grandTotal': yearTotal,
            'repairedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        batchCount++;
        if (batchCount >= 450) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }

        for (final monthEntry in months.entries) {
          final month = monthEntry.key;
          final stats = monthEntry.value;

          batch.set(
            userRef
                .collection('year_stats')
                .doc(year)
                .collection('months')
                .doc(month),
            {
              'month': month,
              'saving': stats['saving'] ?? 0,
              'needed': stats['needed'] ?? 0,
              'luxury': stats['luxury'] ?? 0,
              'grandTotal': stats['grandTotal'] ?? 0,
              'repairedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          batchCount++;
          if (batchCount >= 450) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
      }

      // Update user grand total
      batch.set(
        userRef,
        {
          'grandTotal': overallGrandTotal,
          'lastRepaired': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (batchCount > 0) {
        await batch.commit();
      }

      if (kDebugMode) {
        print("🎉 Data repair completed successfully!");
      }

      _isRepairing = false;
      notifyListeners();

      return {
        'success': true,
        'totalItems': totalItems,
        'totalDates': dateTotals.length,
        'totalYears': yearMonthStats.length,
        'grandTotal': overallGrandTotal,
      };
    } catch (e) {
      debugPrint("❌ Data repair failed: $e");
      _isRepairing = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  /// 🔧 Quick fix for a specific date's total
  Future<bool> repairDateTotal(String dateId) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final dateRef = userRef.collection('expenses').doc(dateId);

      final itemsSnap = await dateRef.collection('items').get();

      double total = 0;
      for (final item in itemsSnap.docs) {
        total += (item.data()['amount'] as num?)?.toDouble() ?? 0;
      }

      await dateRef.set(
        {
          'date': dateId,
          'total': total,
          'repairedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (kDebugMode) {
        print("✅ Repaired $dateId → ₹$total");
      }

      return true;
    } catch (e) {
      debugPrint("❌ Failed to repair $dateId: $e");
      return false;
    }
  }

  /// 🔧 Verify data integrity (check for inconsistencies)
  Future<Map<String, dynamic>> verifyDataIntegrity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'success': false, 'error': 'No user'};

    _isVerifying = true;
    notifyListeners();

    final userRef = _firestore.collection('users').doc(uid);

    try {
      final List<String> issues = [];
      int checkedDates = 0;

      final expenseDatesSnap = await userRef.collection('expenses').get();

      for (final dateDoc in expenseDatesSnap.docs) {
        final dateId = dateDoc.id;
        final storedTotal = (dateDoc.data()['total'] as num?)?.toDouble() ?? 0;

        final itemsSnap = await userRef
            .collection('expenses')
            .doc(dateId)
            .collection('items')
            .get();

        double calculatedTotal = 0;
        for (final item in itemsSnap.docs) {
          calculatedTotal += (item.data()['amount'] as num?)?.toDouble() ?? 0;
        }

        checkedDates++;

        if ((storedTotal - calculatedTotal).abs() > 0.01) {
          issues.add(
              "$dateId: Stored=₹$storedTotal, Actual=₹$calculatedTotal (diff: ₹${storedTotal - calculatedTotal})");
        }
      }

      if (kDebugMode) {
        print("🔍 Verification complete:");
        print("   Checked $checkedDates dates");
        print("   Found ${issues.length} issues");
      }

      _isVerifying = false;
      notifyListeners();

      return {
        'success': true,
        'checkedDates': checkedDates,
        'issuesFound': issues.length,
        'issues': issues,
      };
    } catch (e) {
      debugPrint("❌ Verification failed: $e");
      _isVerifying = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// 📦 BACKUP METADATA MODEL
// ═══════════════════════════════════════════════════════════════

class BackupMetadata {
  final String id;
  final DateTime createdAt;
  final String reason;
  final String? customName;
  final int totalItems;
  final int totalDates;
  final double grandTotal;
  final int issuesFound;

  BackupMetadata({
    required this.id,
    required this.createdAt,
    required this.reason,
    this.customName,
    required this.totalItems,
    required this.totalDates,
    required this.grandTotal,
    required this.issuesFound,
  });

  String get displayName {
    return customName ?? 'Backup ${DateFormat('MMM dd, yyyy HH:mm').format(createdAt)}';
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy • HH:mm').format(createdAt);
  }

  bool get hasIssues => issuesFound > 0;
}