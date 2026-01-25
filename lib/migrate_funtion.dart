import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔄 ONE-TIME MIGRATION FUNCTION
/// Call this once to migrate your existing data to the new structure
///
/// Usage:
/// ```dart
/// ElevatedButton(
///   onPressed: () async {
///     await migrateToNewStructure(context);
///   },
///   child: Text('Migrate Data'),
/// )
/// ```
Future<void> migrateToNewStructure(BuildContext context) async {
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF64FFDA)),
          const SizedBox(height: 16),
          Text(
            'Migrating your data...\nPlease wait, do not close the app',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[300]),
          ),
        ],
      ),
    ),
  );

  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception('No user logged in');
    }

    final db = FirebaseFirestore.instance;

    print('🔄 Starting migration for user: $uid');

    double grandTotalExpense = 0;
    Map<String, double> monthlyTotals = {};
    int datesProcessed = 0;
    int itemsProcessed = 0;

    // Step 1: Get all expense dates
    print('📅 Step 1: Fetching all expense dates...');
    final expensesSnapshot = await db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();

    final totalDates = expensesSnapshot.docs.length;
    print('   Found $totalDates dates to process');

    // Step 2: Process each date
    print('💰 Step 2: Calculating totals for each date...');
    for (var dateDoc in expensesSnapshot.docs) {
      final dateId = dateDoc.id;
      final monthId = dateId.substring(0, 7); // yyyy-MM

      // Get all items for this date
      final itemsSnapshot = await db
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(dateId)
          .collection('items')
          .get();

      // Calculate total for this date
      double dateTotal = 0;
      for (var item in itemsSnapshot.docs) {
        final amount = (item.data()['amount'] as num?)?.toDouble() ?? 0;
        dateTotal += amount;
        itemsProcessed++;
      }

      // Update date document with stored total
      await db
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(dateId)
          .set({
            'date': dateId,
            'total': dateTotal,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      // Accumulate for month and grand total
      monthlyTotals[monthId] = (monthlyTotals[monthId] ?? 0) + dateTotal;
      grandTotalExpense += dateTotal;
      datesProcessed++;

      print(
        '   ✓ Date $dateId: ₹$dateTotal (${itemsSnapshot.docs.length} items)',
      );
    }

    // Step 3: Create/Update monthly data documents
    print('📊 Step 3: Creating monthly data documents...');
    for (var entry in monthlyTotals.entries) {
      final monthId = entry.key;
      final monthTotal = entry.value;

      await db
          .collection('users')
          .doc(uid)
          .collection('monthlyData')
          .doc(monthId)
          .set({
            'month': monthId,
            'totalExpense': monthTotal,
            'income': 0, // Default to 0, user can edit later
            'savings': 0, // Default to 0, user can edit later
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      print('   ✓ Month $monthId: ₹$monthTotal');
    }

    // Step 4: Update user document with grand totals
    print('👤 Step 4: Updating user document...');
    await db.collection('users').doc(uid).set({
      'grandTotalExpense': grandTotalExpense,
      'grandTotalIncome': 0, // Default to 0, user can add via history
      'grandTotalSavings': 0, // Default to 0, user can add via history
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Migration completed successfully!');
    print('📈 Summary:');
    print('   - Dates processed: $datesProcessed');
    print('   - Items processed: $itemsProcessed');
    print('   - Months created: ${monthlyTotals.length}');
    print('   - Grand Total Expense: ₹$grandTotalExpense');

    // Close loading dialog
    navigator.pop();

    // Show success dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
              SizedBox(width: 12),
              Text(
                'Migration Successful!',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your data has been successfully migrated to the new structure.',
                style: TextStyle(color: Colors.grey[300]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow('Dates processed:', '$datesProcessed'),
                    const SizedBox(height: 4),
                    _buildStatRow('Items processed:', '$itemsProcessed'),
                    const SizedBox(height: 4),
                    _buildStatRow('Months created:', '${monthlyTotals.length}'),
                    const Divider(color: Color(0xFF3C3C3C), height: 16),
                    _buildStatRow(
                      'Grand Total:',
                      '₹${grandTotalExpense.toStringAsFixed(2)}',
                      highlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '💡 You can now add income and savings from the History screen!',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: const Color(0xFF121212),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('✅ Migration completed! Processed $datesProcessed dates'),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
      ),
    );
  } catch (e, stackTrace) {
    print('❌ Migration failed: $e');
    print('Stack trace: $stackTrace');

    // Close loading dialog if open
    if (navigator.canPop()) {
      navigator.pop();
    }

    // Show error dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent),
              SizedBox(width: 12),
              Text('Migration Failed', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An error occurred during migration:',
                style: TextStyle(color: Colors.grey[300]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e.toString(),
                  style: TextStyle(
                    color: Colors.redAccent[100],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '💡 Tips:',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Make sure you have internet connection\n'
                '• Check if you\'re logged in\n'
                '• Try again in a few minutes',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: TextStyle(color: Colors.grey[500])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                migrateToNewStructure(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: const Color(0xFF121212),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('❌ Migration failed: ${e.toString()}'),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

// Helper widget for stat rows
Widget _buildStatRow(String label, String value, {bool highlight = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      Text(
        value,
        style: TextStyle(
          color: highlight ? const Color(0xFF64FFDA) : Colors.white,
          fontSize: 13,
          fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    ],
  );
}

/// 🔍 Check if migration is needed
/// Returns true if user has old data that needs migration
Future<bool> needsMigration() async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final db = FirebaseFirestore.instance;

    // Check if user document has grand totals
    final userDoc = await db.collection('users').doc(uid).get();
    final userData = userDoc.data();

    // If no grand totals exist, migration is needed
    if (userData == null || !userData.containsKey('grandTotalExpense')) {
      print('🔍 Migration needed: No grand totals found');
      return true;
    }

    // Check if any expense date document is missing stored total
    final expensesSnapshot = await db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .limit(5) // Check first 5 dates
        .get();

    for (var doc in expensesSnapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('total')) {
        print('🔍 Migration needed: Date ${doc.id} missing stored total');
        return true;
      }
    }

    print('✅ No migration needed');
    return false;
  } catch (e) {
    print('❌ Error checking migration status: $e');
    return false;
  }
}

/// 🎯 EXAMPLE USAGE IN YOUR APP
///
/// Add a migration button to your settings or initial screen:
///
/// ```dart
/// class SettingsScreen extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: Text('Settings')),
///       body: FutureBuilder<bool>(
///         future: needsMigration(),
///         builder: (context, snapshot) {
///           if (snapshot.data == true) {
///             return Center(
///               child: Column(
///                 mainAxisAlignment: MainAxisAlignment.center,
///                 children: [
///                   Icon(Icons.upgrade, size: 64, color: Colors.orange),
///                   SizedBox(height: 16),
///                   Text('Data Migration Required'),
///                   SizedBox(height: 8),
///                   Text('Your data needs to be migrated to the new format'),
///                   SizedBox(height: 24),
///                   ElevatedButton.icon(
///                     onPressed: () => migrateToNewStructure(context),
///                     icon: Icon(Icons.update),
///                     label: Text('Migrate Now'),
///                   ),
///                 ],
///               ),
///             );
///           }
///           return Center(child: Text('No migration needed'));
///         },
///       ),
///     );
///   }
/// }
/// ```
