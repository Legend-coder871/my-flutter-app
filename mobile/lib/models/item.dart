// Data model for an item listed in the marketplace.
class Item {
  final int id;
  final int userId;
  final String name;
  final String description;
  final String category;
  final double price;
  final int quantity;
  final bool isAvailable;
  final String? sellerName;
  final String? sellerPhone;

  Item({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
    required this.isAvailable,
    this.sellerName,
    this.sellerPhone,
  });

  // Build an Item from the JSON returned by the API.
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      isAvailable: json['is_available'] as bool,
      sellerName: json['seller_name'] as String?,
      sellerPhone: json['seller_phone'] as String?,
    );
  }

  // Copy with new values, keeping seller info unless it is provided.
  Item copyWith({
    String? name,
    String? description,
    String? category,
    double? price,
    int? quantity,
    bool? isAvailable,
    String? sellerName,
    String? sellerPhone,
  }) {
    return Item(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isAvailable: isAvailable ?? this.isAvailable,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
    );
  }
}
