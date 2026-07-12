class BillingCycle {
  final DateTime currentStart;
  final DateTime currentEnd;
  final DateTime previousStart;
  final DateTime previousEnd;
  final String currentBillingCycleId;

  const BillingCycle({
    required this.currentStart,
    required this.currentEnd,
    required this.previousStart,
    required this.previousEnd,
    required this.currentBillingCycleId,
  });
}