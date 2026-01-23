import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/expence_provider.dart';

import '../providers/export_provider.dart';
import '../repair tools/setting_page.dart';
import 'anaylitcs_scree.dart';
import 'search_expance_screen.dart';

class HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HistoryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return AppBar(
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Row(
        children: [
          Icon(Icons.history, color: Color(0xFF64FFDA)),
          SizedBox(width: 12),
          Text(
            "Expense History",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<_HistoryMenuAction>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (action) {
            switch (action) {
              case _HistoryMenuAction.export:
                _showExportDialog(context, provider.selectedYear);
                break;

              case _HistoryMenuAction.search:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchExpensesScreen(),
                  ),
                );
                break;

              case _HistoryMenuAction.analytics:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseAnalyticsScreen(
                      year: provider.selectedYear,
                    ),
                  ),
                );
                break;

              case _HistoryMenuAction.settings:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExpenseMaintenancePage(),
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            _menuItem(
              value: _HistoryMenuAction.export,
              icon: Icons.file_download,
              iconColor: const Color(0xFF64FFDA),
              label: "Export Data",
            ),
            _menuItem(
              value: _HistoryMenuAction.search,
              icon: Icons.search,
              iconColor: Colors.blueAccent,
              label: "Search Expenses",
            ),
            _menuItem(
              value: _HistoryMenuAction.analytics,
              icon: Icons.bar_chart,
              iconColor: Colors.purpleAccent,
              label: "Analytics",
            ),
            _menuItem(
              value: _HistoryMenuAction.settings,
              icon: Icons.settings,
              iconColor: Colors.orangeAccent,
              label: "Settings",
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],

    );
  }

  void _showExportDialog(BuildContext context, String year) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF64FFDA).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.file_download,
                color: Color(0xFF64FFDA),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Export Data",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Choose export format for $year expenses",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _ExportOptionTile(
              icon: Icons.picture_as_pdf,
              iconColor: Colors.redAccent,
              title: "Export as PDF",
              subtitle: "Professional report format",
              onTap: () {
                Navigator.pop(context);
                _exportPDF(context, year);
              },
            ),
            const SizedBox(height: 12),
            _ExportOptionTile(
              icon: Icons.table_chart,
              iconColor: Colors.greenAccent,
              title: "Export as Excel",
              subtitle: "Spreadsheet format (.xlsx)",
              onTap: () {
                Navigator.pop(context);
                _exportExcel(context, year);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPDF(BuildContext context, String year) async {
    final exportProvider = context.read<ExportProvider>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Color(0xFF2A2A2A),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF64FFDA)),
                SizedBox(height: 16),
                Text(
                  "Generating PDF...",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final filePath = await exportProvider.exportToPDF(
      year: year,
      context: context,
    );

    // Close loading dialog
    Navigator.pop(context);

    if (filePath != null) {
      _showShareDialog(context, filePath, "PDF");
    }
  }

  Future<void> _exportExcel(BuildContext context, String year) async {
    final exportProvider = context.read<ExportProvider>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Color(0xFF2A2A2A),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF64FFDA)),
                SizedBox(height: 16),
                Text(
                  "Generating Excel...",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final filePath = await exportProvider.exportToExcel(
      year: year,
      context: context,
    );

    // Close loading dialog
    Navigator.pop(context);

    if (filePath != null) {
      _showShareDialog(context, filePath, "Excel");
    }
  }

  void _showShareDialog(BuildContext context, String filePath, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Export Successful",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$type file has been generated successfully!",
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              "File location:",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filePath,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              await Share.shareXFiles(
                [XFile(filePath)],
                text: 'Expense Report',
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text("Share"),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

}
enum _HistoryMenuAction {
  export,
  search,
  analytics,
  settings,
}

PopupMenuItem<_HistoryMenuAction> _menuItem({
  required _HistoryMenuAction value,
  required IconData icon,
  required Color iconColor,
  required String label,
}) {
  return PopupMenuItem<_HistoryMenuAction>(
    value: value,
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}
