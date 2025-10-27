class EventStatistics {
  final int totalNominees;
  final int totalCategories;
  final int totalAccessCodes;
  final int usedCodes;
  final int unusedCodes;
  final int totalVotes;

  EventStatistics({
    required this.totalNominees,
    required this.totalCategories,
    required this.totalAccessCodes,
    required this.usedCodes,
    required this.totalVotes,
  }) : unusedCodes = totalAccessCodes - usedCodes;

  Map<String, dynamic> toMap() => {
    'totalNominees': totalNominees,
    'totalCategories': totalCategories,
    'totalAccessCodes': totalAccessCodes,
    'usedCodes': usedCodes,
    'unusedCodes': unusedCodes,
    'totalVotes': totalVotes,
  };
}
