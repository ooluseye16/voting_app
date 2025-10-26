class Nominee {
  final String id;
  final String name;

  Nominee({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Nominee.fromJson(Map<String, dynamic> json) =>
      Nominee(id: json['id'], name: json['name']);
}