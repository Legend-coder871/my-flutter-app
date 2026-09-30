// Data model for a service offered by a student.
class Service {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String category;
  final double price;
  final bool isActive;
  final String? providerName;
  final String? providerPhone;

  Service({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.isActive,
    this.providerName,
    this.providerPhone,
  });

  // Build a Service from the JSON returned by the API.
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      isActive: json['is_active'] as bool,
      providerName: json['provider_name'] as String?,
      providerPhone: json['provider_phone'] as String?,
    );
  }

  // Copy with new values, keeping provider info unless it is provided.
  Service copyWith({
    String? title,
    String? description,
    String? category,
    double? price,
    bool? isActive,
    String? providerName,
    String? providerPhone,
  }) {
    return Service(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      providerName: providerName ?? this.providerName,
      providerPhone: providerPhone ?? this.providerPhone,
    );
  }
}
