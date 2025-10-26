class VoteResult {
  final String categoryId;
  final String categoryName;
  final Map<String, int> scores;

  VoteResult({
    required this.categoryId,
    required this.categoryName,
    required this.scores,
  });
}