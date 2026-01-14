
class Categoria {
  final int id;
  final String name;
  final String image;

  Categoria({
    required this.id,
    required this.name,
    required this.image,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      name: json['name'],
      image: json['image'],
    );
  }
}
