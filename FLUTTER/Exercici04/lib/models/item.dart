class Item {
  final int id;
  final int categoryId;
  final String name;

  Item({
    required this.id,
    required this.categoryId,
    required this.name,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json["id"],
      categoryId: json["categoryId"],
      name: json["name"],
    );
  }
}
