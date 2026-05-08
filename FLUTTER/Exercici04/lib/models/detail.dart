class Detail {
  final int id;
  final String name;
  final String description;
  final String image;
  final String firstAppearance;

  Detail({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.firstAppearance,
  });

  factory Detail.fromJson(Map<String, dynamic> json) {
    return Detail(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      image: json["image"],
      firstAppearance: json["first_appearance"]
    );
  }
}
