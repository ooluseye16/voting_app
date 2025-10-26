class Vote {
  final String categoryId;
  String? first; // 5 points
  String? second; // 3 points
  String? third; // 1 point

  Vote({required this.categoryId, this.first, this.second, this.third});

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'first': first,
        'second': second,
        'third': third,
      };
}