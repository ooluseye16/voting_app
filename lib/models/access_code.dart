class AccessCode {
  final String code;
  final String generatedFor;
  final DateTime generated;
  final bool used;

  AccessCode({
    required this.code,
    required this.generatedFor,
    required this.generated,
    this.used = false,
  });
}
