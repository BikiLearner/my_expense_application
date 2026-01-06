import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isExporting = false;

  bool get isExporting => _isExporting;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // 🔥 Export to PDF
  Future<String?> exportToPDF({
    required String year,
    required BuildContext context,
  }) async {
    try {
      _isExporting = true;
      notifyListeners();

      // Fetch all expenses for the year
      final expenses = await _fetchYearExpenses(year);
      if (expenses.isEmpty) {
        _showSnackBar(context, "No expenses found for $year");
        _isExporting = false;
        notifyListeners();
        return null;
      }

      // Create PDF
      final pdf = pw.Document();

      // Calculate totals
      double grandTotal = 0;
      final monthlyTotals = <String, double>{};

      for (var expense in expenses) {
        final amount = expense['amount'] as double;
        final dateId = expense['dateId'] as String;
        final month = dateId.substring(0, 7); // yyyy-MM

        grandTotal += amount;
        monthlyTotals[month] = (monthlyTotals[month] ?? 0) + amount;
      }

      // Add title page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1E3A5F'),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Expense Report',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Year: $year',
                        style: const pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Summary',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      _buildSummaryRow(
                        'Total Expenses',
                        '₹${grandTotal.toStringAsFixed(2)}',
                      ),
                      _buildSummaryRow(
                        'Number of Transactions',
                        '${expenses.length}',
                      ),
                      _buildSummaryRow(
                        'Number of Months',
                        '${monthlyTotals.length}',
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Monthly Breakdown
                pw.Text(
                  'Monthly Breakdown',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                ...monthlyTotals.entries.map((entry) {
                  final monthName = DateFormat(
                    'MMMM yyyy',
                  ).format(DateTime.parse('${entry.key}-01'));
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(monthName),
                        pw.Text(
                          '₹${entry.value.toStringAsFixed(2)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );

      // Add detailed expenses pages
      final groupedByMonth = <String, List<Map<String, dynamic>>>{};
      for (var expense in expenses) {
        final dateId = expense['dateId'] as String;
        final month = dateId.substring(0, 7);
        groupedByMonth.putIfAbsent(month, () => []).add(expense);
      }

      for (var monthEntry in groupedByMonth.entries) {
        final monthName = DateFormat(
          'MMMM yyyy',
        ).format(DateTime.parse('${monthEntry.key}-01'));

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    monthName,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      // Header
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildTableCell('Date', isHeader: true),
                          _buildTableCell('Title', isHeader: true),
                          _buildTableCell('Description', isHeader: true),
                          _buildTableCell('Amount', isHeader: true),
                        ],
                      ),
                      // Data rows
                      ...monthEntry.value.map((expense) {
                        return pw.TableRow(
                          children: [
                            _buildTableCell(
                              DateFormat(
                                'dd MMM',
                              ).format(DateTime.parse(expense['dateId'])),
                            ),
                            _buildTableCell(expense['title'] ?? ''),
                            _buildTableCell(expense['description'] ?? '-'),
                            _buildTableCell(
                              '₹${(expense['amount'] as double).toStringAsFixed(2)}',
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      // Save PDF
      final output = await getApplicationDocumentsDirectory();
      final fileName = 'Expense_Report_$year.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      _isExporting = false;
      notifyListeners();

      if (kDebugMode) {
        print('✅ PDF saved to: ${file.path}');
      }

      _showSnackBar(context, "PDF exported successfully!");
      return file.path;
    } catch (e) {
      _isExporting = false;
      notifyListeners();
      if (kDebugMode) {
        print('❌ PDF export failed: $e');
      }
      _showSnackBar(context, "Failed to export PDF: $e");
      return null;
    }
  }

  // 🔥 Export to Excel
  Future<String?> exportToExcel({
    required String year,
    required BuildContext context,
  }) async {
    try {
      _isExporting = true;
      notifyListeners();

      // Fetch all expenses for the year
      final expenses = await _fetchYearExpenses(year);
      if (expenses.isEmpty) {
        _showSnackBar(context, "No expenses found for $year");
        _isExporting = false;
        notifyListeners();
        return null;
      }

      // Create Excel
      final excel = Excel.createExcel();
      final sheet = excel['Expense Report $year'];

      // Set column widths
      sheet.setColumnWidth(0, 15); // Date
      sheet.setColumnWidth(1, 25); // Title
      sheet.setColumnWidth(2, 35); // Description
      sheet.setColumnWidth(3, 15); // Amount

      // Header Style
      final headerStyle = CellStyle(
        fontFamily: getFontFamily(FontFamily.Calibri),
        bold: true,
        fontSize: 12,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A5F'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      // Add title
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('D1'));
      var titleCell = sheet.cell(CellIndex.indexByString('A1'));
      titleCell.value = TextCellValue('Expense Report - $year');
      titleCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 16,
        fontColorHex: ExcelColor.fromHexString('#1E3A5F'),
      );

      // Add generation date
      sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('D2'));
      var dateCell = sheet.cell(CellIndex.indexByString('A2'));
      dateCell.value = TextCellValue(
        'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
      );

      // Headers
      var headers = ['Date', 'Title', 'Description', 'Amount (₹)'];
      for (var i = 0; i < headers.length; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Sort expenses by date
      expenses.sort(
        (a, b) => (a['dateId'] as String).compareTo(b['dateId'] as String),
      );

      // Add data
      double grandTotal = 0;
      for (var i = 0; i < expenses.length; i++) {
        final expense = expenses[i];
        final rowIndex = i + 4;
        final amount = expense['amount'] as double;
        grandTotal += amount;

        // Date
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          DateFormat('dd MMM yyyy').format(DateTime.parse(expense['dateId'])),
        );

        // Title
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          expense['title'] ?? '',
        );

        // Description
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          expense['description'] ?? '-',
        );

        // Amount
        var amountCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
        );
        amountCell.value = DoubleCellValue(amount);
        amountCell.cellStyle = CellStyle(
          numberFormat: NumFormat.custom(formatCode: '#,##0.00'),
        );
      }

      // Add total row
      final totalRowIndex = expenses.length + 5;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRowIndex),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: totalRowIndex),
      );
      var totalLabelCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRowIndex),
      );
      totalLabelCell.value = TextCellValue('GRAND TOTAL');
      totalLabelCell.cellStyle = CellStyle(bold: true, fontSize: 12);

      var totalAmountCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: totalRowIndex),
      );
      totalAmountCell.value = DoubleCellValue(grandTotal);
      totalAmountCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 12,
        numberFormat: NumFormat.custom(formatCode: '#,##0.00'),
        backgroundColorHex: ExcelColor.fromHexString('#64FFDA'),
      );

      // Save Excel
      final output = await getApplicationDocumentsDirectory();
      final fileName = 'Expense_Report_$year.xlsx';
      final file = File('${output.path}/$fileName');

      final excelBytes = excel.encode();
      if (excelBytes != null) {
        await file.writeAsBytes(excelBytes);
      }

      _isExporting = false;
      notifyListeners();

      if (kDebugMode) {
        print('✅ Excel saved to: ${file.path}');
      }

      _showSnackBar(context, "Excel exported successfully!");
      return file.path;
    } catch (e) {
      _isExporting = false;
      notifyListeners();
      if (kDebugMode) {
        print('❌ Excel export failed: $e');
      }
      _showSnackBar(context, "Failed to export Excel: $e");
      return null;
    }
  }

  // Helper: Fetch year expenses
  Future<List<Map<String, dynamic>>> _fetchYearExpenses(String year) async {
    final List<Map<String, dynamic>> expenses = [];

    final datesSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();

    for (var dateDoc in datesSnapshot.docs) {
      final dateId = dateDoc.id;
      if (!dateId.startsWith(year)) continue;

      final itemsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(dateId)
          .collection('items')
          .get();

      for (var item in itemsSnapshot.docs) {
        final data = item.data();
        expenses.add({
          'dateId': dateId,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'amount': (data['amount'] ?? 0).toDouble(),
          'createdAt': data['createdAt'],
        });
      }
    }

    return expenses;
  }

  // Helper: Build PDF summary row
  pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // Helper: Build PDF table cell
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // Helper: Show snackbar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
