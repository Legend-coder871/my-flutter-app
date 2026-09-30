import 'package:flutter/foundation.dart';

import 'package:mobile/models/booking.dart';
import 'package:mobile/services/api_client.dart';

// Format a DateTime as local ISO 8601 without milliseconds: 2030-01-15T10:00:00
String bookingToIso(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}-${two(dt.month)}-${two(dt.day)}'
      'T${two(dt.hour)}:${two(dt.minute)}:00';
}

// Loads and mutates the bookings of the logged-in user.
class BookingsProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<Booking> _mine = [];
  List<Booking> _received = [];
  bool _loading = false;
  String? _error;

  List<Booking> get mine => _mine;
  List<Booking> get received => _received;
  bool get loading => _loading;
  String? get error => _error;

  // Book a service for the current user at the given date and time.
  Future<bool> createBooking({
    required int serviceId,
    required DateTime scheduledAt,
    String? note,
    required String token,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'service_id': serviceId,
        'scheduled_at': bookingToIso(scheduledAt),
      };
      final cleanNote = (note ?? '').trim();
      if (cleanNote.isNotEmpty) body['note'] = cleanNote;
      await _api.post('/bookings', body: body, token: token);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Load the bookings this user made.
  Future<void> loadMine(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/bookings/mine', token: token)
          as List<dynamic>;
      _mine = data
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  // Load the bookings made on this user's services.
  Future<void> loadReceived(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/bookings/received', token: token)
          as List<dynamic>;
      _received = data
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  // Change a booking's status (confirm, decline or cancel).
  Future<bool> updateStatus(int id, String status, String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.patch(
        '/bookings/$id/status',
        body: {'status': status},
        token: token,
      ) as Map<String, dynamic>;
      final updated = Booking.fromJson(data);
      _mine = [for (final b in _mine) b.id == id ? _merge(b, updated) : b];
      _received = [
        for (final b in _received) b.id == id ? _merge(b, updated) : b,
      ];
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // The status response has no joins, so keep the old joined names.
  Booking _merge(Booking old, Booking updated) {
    return Booking(
      id: updated.id,
      serviceId: updated.serviceId,
      serviceTitle: updated.serviceTitle.isEmpty
          ? old.serviceTitle
          : updated.serviceTitle,
      scheduledAt: updated.scheduledAt,
      note: updated.note,
      status: updated.status,
      providerName: updated.providerName ?? old.providerName,
      providerPhone: updated.providerPhone ?? old.providerPhone,
      customerName: updated.customerName ?? old.customerName,
      customerPhone: updated.customerPhone ?? old.customerPhone,
    );
  }
}
