class YearStats {
  final String year;
  final double grandTotal;

  YearStats({required this.year, required this.grandTotal});

  factory YearStats.fromFirestore(String year, Map<String, dynamic> data) {
    return YearStats(
      year: year,
      grandTotal: (data['grandTotal'] ?? 0).toDouble(),
    );
  }
}
