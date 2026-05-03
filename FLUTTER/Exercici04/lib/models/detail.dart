class Detail {
  final int id;
  final String name;
  final String description;
  final String image;

  Detail({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
  });

  factory Detail.fromJson(Map<String, dynamic> json) {
    return Detail(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      image: json["image"],
    );
  }
}
