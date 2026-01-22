import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/setting_provider.dart';

class ExpenseMaintenancePage extends StatefulWidget {
  const ExpenseMaintenancePage({super.key});

  @override
  State<ExpenseMaintenancePage> createState() => _ExpenseMaintenancePageState();
}

class _ExpenseMaintenancePageState extends State<ExpenseMaintenancePage> {
  @override
  void initState() {
    super.initState();
    // Fetch backups when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchBackups();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.settings, color: Color(0xFF64FFDA)),
            SizedBox(width: 12),
            Text(
              "Settings & Maintenance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                icon: Icons.build,
                title: "Data Repair Tools",
                subtitle: "Fix inconsistencies in your expense data",
              ),
              const SizedBox(height: 12),
              _buildRepairSection(),
              const SizedBox(height: 32),
              _buildSectionHeader(
                icon: Icons.backup,
                title: "Backup & Restore",
                subtitle: "Protect your data with backups",
              ),
              const SizedBox(height: 12),
              _buildBackupSection(),
              const SizedBox(height: 32),
              _buildSectionHeader(
                icon: Icons.history,
                title: "Backup History",
                subtitle: "View and manage your backups",
              ),
              const SizedBox(height: 12),
              _buildBackupList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF64FFDA).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF64FFDA), size: 24),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepairSection() {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C2C2C)),
          ),
          child: Column(
            children: [
              _buildActionTile(
                icon: Icons.search,
                iconColor: Colors.blueAccent,
                title: "Verify Data Integrity",
                subtitle: "Check for inconsistencies without making changes",
                isLoading: provider.isVerifying,
                onTap: () => _verifyData(context),
              ),
              const SizedBox(height: 16),
              _buildActionTile(
                icon: Icons.auto_fix_high,
                iconColor: Colors.orangeAccent,
                title: "Repair All Data",
                subtitle: "Recalculate all totals from expense items",
                isLoading: provider.isRepairing,
                onTap: () => _showRepairConfirmation(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackupSection() {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2C2C2C)),
          ),
          child: Column(
            children: [
              _buildActionTile(
                icon: Icons.save,
                iconColor: Colors.greenAccent,
                title: "Create Backup",
                subtitle: "Save a snapshot of all your expense data",
                isLoading: provider.isCreatingBackup,
                onTap: () => _showCreateBackupDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackupList() {
    return Consumer<SettingsProvider>(
      builder: (context, provider, _) {
        if (provider.backups.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2C2C2C)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.backup_outlined, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  Text(
                    "No backups yet",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Create your first backup to protect your data",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: provider.backups.map((backup) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: backup.hasIssues
                      ? Colors.orangeAccent.withOpacity(0.3)
                      : const Color(0xFF2C2C2C),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: backup.hasIssues
                              ? Colors.orangeAccent.withOpacity(0.15)
                              : Colors.greenAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          backup.hasIssues ? Icons.warning : Icons.backup,
                          color: backup.hasIssues
                              ? Colors.orangeAccent
                              : Colors.greenAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              backup.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              backup.formattedDate,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildBackupStat(
                        icon: Icons.receipt,
                        value: backup.totalItems.toString(),
                        label: "Items",
                      ),
                      const SizedBox(width: 16),
                      _buildBackupStat(
                        icon: Icons.calendar_today,
                        value: backup.totalDates.toString(),
                        label: "Days",
                      ),
                      const SizedBox(width: 16),
                      _buildBackupStat(
                        icon: Icons.currency_rupee,
                        value: backup.grandTotal.toStringAsFixed(0),
                        label: "Total",
                      ),
                    ],
                  ),
                  if (backup.reason.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              backup.reason,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (backup.hasIssues) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.warning_amber,
                            size: 16, color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        Text(
                          "${backup.issuesFound} issues found",
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRestoreConfirmation(context, backup),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF64FFDA),
                            side: const BorderSide(color: Color(0xFF64FFDA)),
                          ),
                          icon: const Icon(Icons.restore, size: 18),
                          label: const Text("Restore"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showDeleteBackupConfirmation(context, backup),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text("Delete"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildBackupStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isLoading
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: iconColor,
                ),
              )
                  : Icon(icon, color: iconColor, size: 24),
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
            if (!isLoading)
              Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOG FUNCTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _verifyData(BuildContext context) async {
    final provider = context.read<SettingsProvider>();
    final result = await provider.verifyDataIntegrity();

    if (!mounted) return;

    if (result['success'] == true) {
      final issuesFound = result['issuesFound'] ?? 0;
      final checkedDates = result['checkedDates'] ?? 0;

      _showResultDialog(
        context: context,
        success: issuesFound == 0,
        title: issuesFound == 0 ? "All Clear!" : "Issues Found",
        message: issuesFound == 0
            ? "Checked $checkedDates dates. No inconsistencies found!"
            : "Found $issuesFound inconsistencies in your data.\n\nRun 'Repair All Data' to fix them.",
        icon: issuesFound == 0 ? Icons.check_circle : Icons.warning,
      );
    }
  }

  void _showRepairConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text("Repair All Data?", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This will:",
              style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint("Create a backup of current data"),
            _buildBulletPoint("Recalculate all totals from expense items"),
            _buildBulletPoint("Fix any inconsistencies"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "A backup will be created automatically before repair",
                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _repairData(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text("Repair Now"),
          ),
        ],
      ),
    );
  }

  Future<void> _repairData(BuildContext context) async {
    final provider = context.read<SettingsProvider>();
    final result = await provider.repairAllData();

    if (!mounted) return;

    if (result['success'] == true) {
      _showResultDialog(
        context: context,
        success: true,
        title: "Repair Complete!",
        message:
        "Fixed ${result['totalDates']} dates\n${result['totalItems']} items processed\nGrand Total: ₹${result['grandTotal']}",
        icon: Icons.check_circle,
      );
    } else {
      _showResultDialog(
        context: context,
        success: false,
        title: "Repair Failed",
        message: result['error'] ?? "Unknown error occurred",
        icon: Icons.error,
      );
    }
  }

  void _showCreateBackupDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.greenAccent),
            SizedBox(width: 12),
            Text("Create Backup", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Backup Name (Optional)",
                hintText: "e.g., Monthly Backup",
                labelStyle: TextStyle(color: Colors.grey[500]),
                hintStyle: TextStyle(color: Colors.grey[700]),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Reason",
                hintText: "e.g., Before major changes",
                labelStyle: TextStyle(color: Colors.grey[500]),
                hintStyle: TextStyle(color: Colors.grey[700]),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;

              Navigator.pop(ctx);

              final provider = context.read<SettingsProvider>();
              final backupId = await provider.createBackup(
                reason: reason,
                customName: nameController.text.trim().isEmpty
                    ? null
                    : nameController.text.trim(),
              );

              if (mounted && backupId != null) {
                _showResultDialog(
                  context: context,
                  success: true,
                  title: "Backup Created!",
                  message: "Your data has been backed up successfully.",
                  icon: Icons.check_circle,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showRestoreConfirmation(BuildContext context, BackupMetadata backup) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.restore, color: Color(0xFF64FFDA)),
            SizedBox(width: 12),
            Text("Restore Backup?", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Restore from: ${backup.displayName}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "This will:",
              style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint("Create a backup of current data"),
            _buildBulletPoint("Delete all current expenses"),
            _buildBulletPoint("Restore data from backup"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "This action cannot be undone!",
                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _restoreBackup(context, backup);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: Colors.black,
            ),
            child: const Text("Restore"),
          ),
        ],
      ),
    );
  }

  Future<void> _restoreBackup(BuildContext context, BackupMetadata backup) async {
    final provider = context.read<SettingsProvider>();
    final success = await provider.restoreFromBackup(backupId: backup.id);

    if (!mounted) return;

    _showResultDialog(
      context: context,
      success: success,
      title: success ? "Restore Complete!" : "Restore Failed",
      message: success
          ? "Your data has been restored from ${backup.displayName}"
          : "Failed to restore backup. Please try again.",
      icon: success ? Icons.check_circle : Icons.error,
    );
  }

  void _showDeleteBackupConfirmation(BuildContext context, BackupMetadata backup) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete, color: Colors.redAccent),
            SizedBox(width: 12),
            Text("Delete Backup?", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          "Are you sure you want to delete '${backup.displayName}'?\n\nThis action cannot be undone.",
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<SettingsProvider>();
              await provider.deleteBackup(backup.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showResultDialog({
    required BuildContext context,
    required bool success,
    required String title,
    required String message,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (success ? Colors.greenAccent : Colors.redAccent)
                    .withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: success ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: Colors.black,
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("• ", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ),
        ],
      ),
    );
  }
}