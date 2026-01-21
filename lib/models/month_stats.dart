class MonthStats {
  final String month; // yyyy-MM
  final double saving;
  final double needed;
  final double luxury;
  final double grandTotal;

  MonthStats({
    required this.month,
    required this.saving,
    required this.needed,
    required this.luxury,
    required this.grandTotal,
  });

  factory MonthStats.fromFirestore(
      String month,
      Map<String, dynamic> data,
      ) {
    return MonthStats(
      month: month,
      saving: (data['saving'] ?? 0).toDouble(),
      needed: (data['needed'] ?? 0).toDouble(),
      luxury: (data['luxury'] ?? 0).toDouble(),
      grandTotal: (data['grandTotal'] ?? 0).toDouble(),
    );
  }
}
