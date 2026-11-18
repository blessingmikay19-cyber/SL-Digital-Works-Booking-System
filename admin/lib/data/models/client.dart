import '../../core/formatters.dart';

class Client {
  Client({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.notes,
    required this.createdAt,
    required this.bookingCount,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String notes;
  final DateTime createdAt; // SAST wall-clock time
  final int bookingCount;

  String get initial => fullName.isEmpty ? '?' : fullName[0].toUpperCase();

  factory Client.fromMap(Map<String, dynamic> m) {
    var count = 0;
    final b = m['bookings'];
    if (b is List && b.isNotEmpty) count = (b.first['count'] as num).toInt();
    return Client(
      id: m['id'] as String,
      fullName: (m['full_name'] ?? '') as String,
      email: (m['email'] ?? '') as String,
      phone: (m['phone'] ?? '') as String,
      notes: (m['notes'] ?? '') as String,
      createdAt: toSast(DateTime.parse(m['created_at'] as String)),
      bookingCount: count,
    );
  }
}
