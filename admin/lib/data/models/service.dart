class Service {
  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.active,
  });

  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final num price;
  final bool active;

  String get priceLabel {
    if (price <= 0) return 'Free';
    return price == price.roundToDouble() ? 'R${price.toInt()}' : 'R${price.toStringAsFixed(2)}';
  }

  factory Service.fromMap(Map<String, dynamic> m) => Service(
        id: m['id'] as String,
        name: (m['name'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        durationMinutes: (m['duration_minutes'] as num).toInt(),
        price: (m['price'] as num?) ?? 0,
        active: (m['active'] as bool?) ?? true,
      );
}
