// Data model for a service appointment.
class Booking {
  final int id;
  final int serviceId;
  final String serviceTitle;
  final DateTime scheduledAt;
  final String? note;
  final String status;
  final String? providerName;
  final String? providerPhone;
  final String? customerName;
  final String? customerPhone;

  Booking({
    required this.id,
    required this.serviceId,
    required this.serviceTitle,
    required this.scheduledAt,
    this.note,
    required this.status,
    this.providerName,
    this.providerPhone,
    this.customerName,
    this.customerPhone,
  });

  // Build a Booking from the JSON returned by the API.
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      serviceId: json['service_id'] as int,
      serviceTitle: json['service_title'] as String? ?? '',
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      note: json['note'] as String?,
      status: json['status'] as String,
      providerName: json['provider_name'] as String?,
      providerPhone: json['provider_phone'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
    );
  }
}
