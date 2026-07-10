import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:expence_app/core/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../firebase_options.dart';

enum ExportType { pdf, excel }

// 🔧 Background Task Callback (Must be top-level)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      debugPrint("=" * 80);
      debugPrint("🚀 BACKGROUND WORKER STARTED");
      debugPrint("Task: $task");
      debugPrint("Input Data: $inputData");
      debugPrint("=" * 80);

      // ⭐ CRITICAL: Initialize Firebase in background isolate
      try {
        debugPrint("🔧 Initializing Firebase...");
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.android,
        );
        debugPrint("✅ Firebase initialized successfully");
      } catch (e) {
        debugPrint("⚠️ Firebase initialization warning (might already be initialized): $e");
      }

      if (task == 'exportTask') {
        final year = inputData!['year'] as String;
        final month = inputData['month'] as String?;
        final typeStr = inputData['type'] as String;
        final uid = inputData['uid'] as String;

        debugPrint("📊 Export params:");
        debugPrint("  - Year: $year");
        debugPrint("  - Month: ${month ?? 'all'}");
        debugPrint("  - Type: $typeStr");
        debugPrint("  - UID: $uid");

        final type = typeStr == 'pdf' ? ExportType.pdf : ExportType.excel;

        // Execute export
        await _executeBackgroundExport(
            uid: uid,
            year: year,
            month: month,
            type: type
        );

        debugPrint("✅ Background export completed successfully");
        debugPrint("=" * 80);
        return Future.value(true);
      }

      debugPrint("❌ Unknown task: $task");
      return Future.value(false);
    } catch (e, stack) {
      debugPrint("=" * 80);
      debugPrint("❌ BACKGROUND WORKER ERROR");
      debugPrint("Error: $e");
      debugPrint("Stack trace:");
      debugPrint(stack.toString());
      debugPrint("=" * 80);

      try {
        await NotificationService.showCompletion(
          1,
          'Export Failed ❌',
          'Error: ${e.toString().substring(0, 50)}...',
          null,
        );
      } catch (_) {}

      return Future.value(false);
    }
  });
}

// Background execution logic
Future<void> _executeBackgroundExport({
  required String uid,
  required String year,
  String? month,
  required ExportType type,
}) async {
  try {
    debugPrint("\n--- STEP 1: SHOW INITIAL NOTIFICATION ---");
    await NotificationService.showProgress(
        1,
        10,
        100,
        'Exporting Data',
        'Fetching from database...'
    );

    debugPrint("\n--- STEP 2: FETCH DATA FROM FIRESTORE ---");
    debugPrint("🔍 Fetching data for $year${month != null ? '-$month' : ''}");

    final allYearData = await _fetchYearExpensesStatic(uid, year);
    debugPrint("📦 Fetched ${allYearData.length} total records");

    if (allYearData.isEmpty) {
      throw Exception("No data found for year $year");
    }

    debugPrint("\n--- STEP 3: UPDATE PROGRESS ---");
    await NotificationService.showProgress(
        1,
        40,
        100,
        'Exporting Data',
        'Filtering ${allYearData.length} records...'
    );

    debugPrint("\n--- STEP 4: FILTER DATA ---");
    List<Map<String, dynamic>> filteredData;
    if (month == null || month == 'all') {
      filteredData = allYearData;
      debugPrint("🔎 Using all records (no month filter)");
    } else {
      filteredData = allYearData.where((e) {
        final dateId = e['dateId'] as String;
        return dateId.startsWith('$year-$month');
      }).toList();
      debugPrint("🔎 Filtered to ${filteredData.length} records for month $month");
    }

    if (filteredData.isEmpty) {
      throw Exception("No data found for ${month ?? 'all'}/$year");
    }

    debugPrint("\n--- STEP 5: UPDATE PROGRESS ---");
    await NotificationService.showProgress(
        1,
        70,
        100,
        'Exporting Data',
        'Generating ${type == ExportType.pdf ? 'PDF' : 'Excel'}...'
    );

    debugPrint("\n--- STEP 6: GENERATE FILE ---");
    debugPrint("📄 Generating ${type == ExportType.pdf ? 'PDF' : 'Excel'}...");
    String? filePath;

    if (type == ExportType.pdf) {
      filePath = await _generatePdfIsolate({
        'data': filteredData,
        'year': year,
        'month': month ?? 'All'
      });
    } else {
      filePath = await _generateExcelIsolate({
        'data': filteredData,
        'year': year
      });
    }

    debugPrint("💾 File saved at: $filePath");

    debugPrint("\n--- STEP 7: SHOW COMPLETION NOTIFICATION ---");
    await NotificationService.showCompletion(
      1,
      'Export Complete ✅',
      '${filteredData.length} records exported. Tap to open.',
      filePath,
    );

    debugPrint("\n--- EXPORT COMPLETED SUCCESSFULLY ---\n");

  } catch (e, stack) {
    debugPrint("\n--- EXPORT FAILED ---");
    debugPrint("❌ Error: $e");
    debugPrint("Stack trace:");
    debugPrint(stack.toString());

    await NotificationService.showCompletion(
      1,
      'Export Failed ❌',
      e.toString().length > 100
          ? '${e.toString().substring(0, 100)}...'
          : e.toString(),
      null,
    );
    rethrow;
  }
}

// Static fetch method for background
Future<List<Map<String, dynamic>>> _fetchYearExpensesStatic(String uid, String year) async {
  final List<Map<String, dynamic>> expenses = [];

  try {
    debugPrint("📡 Connecting to Firestore...");
    final firestore = FirebaseFirestore.instance;

    debugPrint("📡 Querying: users/$uid/expenses (year: $year)");
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: '$year-01-01')
        .where(FieldPath.documentId, isLessThanOrEqualTo: '$year-12-31')
        .get();

    debugPrint("📥 Query returned ${snapshot.docs.length} date documents");

    for (var dateDoc in snapshot.docs) {
      final dateId = dateDoc.id;
      // debugPrint("  📄 Processing date: $dateId"); // Verbose

      final itemsSnapshot = await dateDoc.reference.collection('items').get();
      // debugPrint("    ✓ Found ${itemsSnapshot.docs.length} items"); // Verbose

      for (var item in itemsSnapshot.docs) {
        final data = item.data();
        expenses.add({
          'dateId': dateId,
          'title': data['title'] ?? 'Unknown',
          'description': data['description'] ?? '-',
          'amount': (data['amount'] ?? 0).toDouble(),
          'dateStr': dateId,
        });
      }
    }

    debugPrint("✅ Total expenses collected: ${expenses.length}");
  } catch (e, stack) {
    debugPrint("❌ Firestore fetch error: $e");
    debugPrint("Stack trace:");
    debugPrint(stack.toString());
    rethrow;
  }

  return expenses;
}

class ExportProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String get uid => FirebaseAuth.instance.currentUser!.uid;
  List<FileSystemEntity> _exportedFiles = [];
  List<FileSystemEntity> get exportedFiles => _exportedFiles;

  // Initialize WorkManager


  /// 🚀 MAIN ENTRY POINT
  Future<void> startExport({
    required BuildContext context,
    required String year,
    String? month,
    required ExportType type,
    bool useBackground = true,
  }) async {
    _isExporting = true;
    notifyListeners();

    debugPrint("🚀 Starting export: year=$year, month=${month ?? 'all'}, type=$type, bg=$useBackground");

    try {
      if (useBackground) {
        debugPrint("📅 Scheduling background task...");

        await Workmanager().registerOneOffTask(
          "export_${DateTime.now().millisecondsSinceEpoch}",
          "exportTask",
          inputData: {
            'year': year,
            'month': month ?? 'all',
            'type': type == ExportType.pdf ? 'pdf' : 'excel',
            'uid': uid,
          },
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
        );

        debugPrint("✅ Background task scheduled successfully");
        _showSnackBar(context, "Export started in background. Check notifications.");

      } else {
        debugPrint("🔄 Running foreground export...");
        await _runForegroundExport(context, year, month, type);
      }

    } catch (e, stack) {
      debugPrint("❌ Export Error: $e");
      debugPrint("Stack: ${stack.toString().substring(0, 200)}");
      _showSnackBar(context, "Export failed: ${e.toString()}");
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  // Foreground export
  Future<void> _runForegroundExport(
      BuildContext context,
      String year,
      String? month,
      ExportType type,
      ) async {
    try {
      debugPrint("📊 Starting foreground export");
      await NotificationService.showProgress(1, 0, 100, 'Exporting Data', 'Fetching data...');

      debugPrint("🔍 Fetching year expenses...");
      final allYearData = await _fetchYearExpenses(year);
      debugPrint("📦 Fetched ${allYearData.length} records");

      if (allYearData.isEmpty) {
        throw Exception("No data found for year $year");
      }

      await NotificationService.showProgress(1, 30, 100, 'Exporting Data', 'Filtering data...');

      List<Map<String, dynamic>> filteredData;
      if (month == null || month == 'all') {
        filteredData = allYearData;
      } else {
        filteredData = allYearData.where((e) {
          final dateId = e['dateId'] as String;
          return dateId.startsWith('$year-$month');
        }).toList();
      }

      debugPrint("🔎 Filtered to ${filteredData.length} records");

      if (filteredData.isEmpty) {
        throw Exception("No data found for $month/$year");
      }

      await NotificationService.showProgress(1, 60, 100, 'Exporting Data', 'Generating file...');
      debugPrint("📄 Generating file...");

      String? filePath;
      if (type == ExportType.pdf) {
        // Use compute for heavy PDF generation to keep UI responsive
        filePath = await compute(_generatePdfIsolate, {
          'data': filteredData,
          'year': year,
          'month': month ?? 'All'
        });
      } else {
        // Use compute for Excel too
        filePath = await compute(_generateExcelIsolate, {
          'data': filteredData,
          'year': year
        });
      }

      debugPrint("💾 File generated: $filePath");

      await NotificationService.showCompletion(1, 'Export Complete ✅', 'Tap to open file', filePath);

      _showSnackBar(context, "Export successful!");

      if (filePath != null) {
        debugPrint("📂 Opening file...");
        OpenFile.open(filePath);
      }

      await loadExportedFiles();

    } catch (e) {
      debugPrint("❌ Foreground export failed: $e");
      rethrow;
    }
  }

  // Fetch Helper
  Future<List<Map<String, dynamic>>> _fetchYearExpenses(String year) async {
    return await _fetchYearExpensesStatic(uid, year);
  }

  /// 📂 Load list of exported files
  Future<void> loadExportedFiles() async {
    try {
      debugPrint("📂 Loading exported files...");
      final persistentDir = await getApplicationDocumentsDirectory();

      if (!persistentDir.existsSync()) {
        _exportedFiles = [];
        notifyListeners();
        return;
      }

      final files = persistentDir.listSync()
          .where((file) => file.path.endsWith('.pdf') || file.path.endsWith('.xlsx'))
          .toList();

      // Sort Newest First
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      _exportedFiles = files;
      debugPrint("✅ Loaded ${files.length} files");
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading files: $e");
    }
  }

  /// 🗑️ Delete a file
  Future<void> deleteFile(String path) async {
    try {
      debugPrint("🗑️ Deleting: $path");
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        debugPrint("✅ File deleted");
        await loadExportedFiles();
      }
    } catch (e) {
      debugPrint("❌ Error deleting file: $e");
    }
  }

  /// 📤 Share a specific file
  Future<void> shareFile(String path) async {
    debugPrint("📤 Sharing: $path");
    await Share.shareXFiles([XFile(path)]);
  }

  void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

// -----------------------------------------------------------------------------
// 🧵 ISOLATE FUNCTIONS (Top-level)
// -----------------------------------------------------------------------------

Future<String> _generatePdfIsolate(Map<String, dynamic> params) async {
  debugPrint("📄 PDF Generation started");
  final expenses = params['data'] as List<Map<String, dynamic>>;
  final year = params['year'] as String;
  final monthSelection = params['month'] as String;

  debugPrint("  - Records to process: ${expenses.length}");

  final pdf = pw.Document();

  // Sort
  expenses.sort((a, b) => (a['dateStr'] as String).compareTo(b['dateStr']));

  double total = expenses.fold(0, (sum, item) => sum + (item['amount'] as double));
  debugPrint("  - Total amount: $total");

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return [
          pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Expense Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Year: $year | Month: $monthSelection', style: const pw.TextStyle(fontSize: 14)),
                ],
              )
          ),
          pw.SizedBox(height: 20),
          pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Transactions: ${expenses.length}'),
                    pw.Text('Total Amount: ${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]
              )
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Title', 'Desc', 'Amount'],
            data: expenses.map((e) => [
              e['dateStr'],
              e['title'],
              e['description'],
              e['amount'].toStringAsFixed(2)
            ]).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
            },
          ),
        ];
      },
    ),
  );

  final output = await getApplicationDocumentsDirectory();
  final fileName = 'Expenses_${year}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final file = File('${output.path}/$fileName');
  await file.writeAsBytes(await pdf.save());

  debugPrint("✅ PDF saved: ${file.path}");
  return file.path;
}

Future<String> _generateExcelIsolate(Map<String, dynamic> params) async {
  debugPrint("📊 Excel Generation started");
  final expenses = params['data'] as List<Map<String, dynamic>>;
  final year = params['year'] as String;

  debugPrint("  - Records to process: ${expenses.length}");

  var excel = Excel.createExcel();
  Sheet sheetObject = excel['Sheet1'];

  sheetObject.appendRow([
    TextCellValue('Date'),
    TextCellValue('Title'),
    TextCellValue('Description'),
    TextCellValue('Amount')
  ]);

  for (var e in expenses) {
    sheetObject.appendRow([
      TextCellValue(e['dateStr']),
      TextCellValue(e['title']),
      TextCellValue(e['description']),
      DoubleCellValue((e['amount'] as num).toDouble()),
    ]);
  }

  final output = await getApplicationDocumentsDirectory();
  final fileName = 'Expenses_${year}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  final file = File('${output.path}/$fileName');

  var fileBytes = excel.save();
  if (fileBytes != null) {
    await file.writeAsBytes(fileBytes);
  }

  debugPrint("✅ Excel saved: ${file.path}");
  return file.path;
}