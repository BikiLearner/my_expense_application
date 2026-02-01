import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/export_provider.dart';

class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  final List<String> availableYears = [
    DateTime.now().year.toString(),
    (DateTime.now().year - 1).toString(),
    (DateTime.now().year - 2).toString(),
  ];

  String? selectedYear;
  String selectedMonth = 'all';
  ExportType selectedFormat = ExportType.pdf;
  bool useBackgroundExport = true; // NEW: Toggle for background processing
  bool showDebugLogs = false; // NEW: Toggle debug log viewer

  @override
  void initState() {
    super.initState();
    _checkPermissions();

    // Load files when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExportProvider>().loadExportedFiles();
    });
  }


  Future<void> _checkPermissions() async {
    await Permission.notification.request();
    // For Android 13+, also request POST_NOTIFICATIONS
    if (await Permission.notification.isDenied) {
      debugPrint("⚠️ Notification permission denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExportProvider>();
    final isExporting = provider.isExporting;
    final files = provider.exportedFiles;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Export Data', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [

          // --- TOP SECTION: CONTROLS ---
          Expanded(
            flex: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildYearSelector(isExporting),
                  const SizedBox(height: 16),
                  _buildMonthSelector(isExporting),
                  const SizedBox(height: 20),
                  _buildFormatSelector(isExporting),
                  const SizedBox(height: 16),

                  // NEW: Background Export Toggle
                  _buildBackgroundToggle(isExporting),

                  const SizedBox(height: 24),
                  _buildExportButton(context, provider),
                ],
              ),
            ),
          ),

          // --- BOTTOM SECTION: FILE LIST ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recent Exports",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
                        onPressed: () => provider.loadExportedFiles(),
                        tooltip: 'Refresh list',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (files.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          "No exported files yet.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          final file = files[index];
                          final name = file.path.split('/').last;
                          final isPdf = name.endsWith('.pdf');
                          final stat = file.statSync();
                          final dateStr = DateFormat('MMM dd, hh:mm a').format(stat.modified);
                          final sizeKB = (stat.size / 1024).toStringAsFixed(1);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isPdf
                                      ? Colors.redAccent.withOpacity(0.2)
                                      : Colors.greenAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isPdf ? Icons.picture_as_pdf : Icons.table_chart,
                                  color: isPdf ? Colors.redAccent : Colors.greenAccent,
                                ),
                              ),
                              title: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              subtitle: Text(
                                '$dateStr • $sizeKB KB',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 📤 Share Button
                                  IconButton(
                                    icon: const Icon(Icons.share, color: Colors.blueAccent),
                                    onPressed: () => provider.shareFile(file.path),
                                  ),
                                  // 👁 Open Button
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new, color: Color(0xFF64FFDA)),
                                    onPressed: () => OpenFile.open(file.path),
                                  ),
                                  // 🗑 Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                    onPressed: () => _confirmDelete(context, provider, file.path, name),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildYearSelector(bool disabled) {
    return DropdownButtonFormField<String>(
      value: selectedYear,
      dropdownColor: const Color(0xFF2C2C2C),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Year (Required)'),
      items: availableYears.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
      onChanged: disabled ? null : (val) => setState(() => selectedYear = val),
    );
  }

  Widget _buildMonthSelector(bool disabled) {
    return DropdownButtonFormField<String>(
      value: selectedMonth,
      dropdownColor: const Color(0xFF2C2C2C),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration('Month (Optional)'),
      items: [
        const DropdownMenuItem(value: 'all', child: Text('All Months')),
        ...List.generate(12, (i) {
          final date = DateTime(0, i + 1);
          return DropdownMenuItem(
            value: (i + 1).toString().padLeft(2, '0'),
            child: Text(DateFormat.MMMM().format(date)),
          );
        }),
      ],
      onChanged: disabled ? null : (val) => setState(() => selectedMonth = val!),
    );
  }

  Widget _buildFormatSelector(bool disabled) {
    return Row(
      children: [
        Expanded(
          child: _formatRadioTile("PDF", ExportType.pdf, Icons.picture_as_pdf, Colors.redAccent, disabled),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _formatRadioTile("Excel", ExportType.excel, Icons.table_chart, Colors.greenAccent, disabled),
        ),
      ],
    );
  }

  Widget _formatRadioTile(String title, ExportType type, IconData icon, Color color, bool disabled) {
    final isSelected = selectedFormat == type;
    return GestureDetector(
      onTap: disabled ? null : () => setState(() => selectedFormat = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Background Export Toggle
  Widget _buildBackgroundToggle(bool disabled) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            useBackgroundExport ? Icons.cloud_done : Icons.phone_android,
            color: useBackgroundExport ? Colors.blueAccent : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  useBackgroundExport ? 'Background Export (Recommended)' : 'Foreground Export',
                  style: TextStyle(
                    color: useBackgroundExport ? Colors.blueAccent : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  useBackgroundExport
                      ? 'Works even if app is closed or paused'
                      : 'Requires app to stay open',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: useBackgroundExport,
            onChanged: disabled ? null : (val) => setState(() => useBackgroundExport = val),
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, ExportProvider provider) {
    final disabled = selectedYear == null || provider.isExporting;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF64FFDA),
          disabledBackgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: disabled
            ? null
            : () async {
          await provider.startExport(
            context: context,
            year: selectedYear!,
            month: selectedMonth == 'all' ? null : selectedMonth,
            type: selectedFormat,
            useBackground: useBackgroundExport, // Pass the toggle value
          );

          // Refresh list after export
          if (context.mounted) {
            await Future.delayed(const Duration(seconds: 1));
            provider.loadExportedFiles();
          }
        },
        child: provider.isExporting
            ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 3)
            : Text(
          useBackgroundExport ? "START BACKGROUND EXPORT" : "GENERATE REPORT",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  // Confirm delete dialog
  Future<void> _confirmDelete(BuildContext context, ExportProvider provider, String path, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Delete File?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.deleteFile(path);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}