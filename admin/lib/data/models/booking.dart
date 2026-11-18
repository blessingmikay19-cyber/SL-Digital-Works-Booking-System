import '../../core/formatters.dart';

enum BookingStatus { pending, confirmed, completed, cancelled }

class Booking {
  Booking({
    required this.id,
    required this.start,
    required this.end,
    required this.status,
    required this.notes,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.serviceName,
    required this.price,
  });

  final String id;
  final DateTime start; // SAST wall-clock time
  final DateTime end;
  final BookingStatus status;
  final String notes;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String serviceName;
  final num price;

  factory Booking.fromMap(Map<String, dynamic> m) {
    final client = (m['clients'] ?? {}) as Map;
    final service = (m['services'] ?? {}) as Map;
    return Booking(
      id: m['id'] as String,
      start: toSast(DateTime.parse(m['start_time'] as String)),
      end: toSast(DateTime.parse(m['end_time'] as String)),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => BookingStatus.pending,
      ),
      notes: (m['notes'] as String?) ?? '',
      clientName: (client['full_name'] ?? '') as String,
      clientEmail: (client['email'] ?? '') as String,
      clientPhone: (client['phone'] ?? '') as String,
      serviceName: (service['name'] ?? '') as String,
      price: (service['price'] as num?) ?? 0,
    );
  }
}
