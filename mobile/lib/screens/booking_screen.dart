import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/service.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/bookings_provider.dart';

// Format a date as "15 Jan 2030".
String formatBookingDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

// Format a time as "10:00 AM".
String formatBookingTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  return '$hour12:${two(dt.minute)} $ampm';
}

// Small screen used to book an appointment on a service.
class BookingScreen extends StatefulWidget {
  final Service service;

  const BookingScreen({super.key, required this.service});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _noteController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Pick a date from today onwards.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month, now.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2, now.month, now.day),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // Pick a time of day.
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  // Send the booking to the API.
  Future<void> _confirm() async {
    if (_date == null || _time == null) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final when = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    final provider = context.read<BookingsProvider>();
    final ok = await provider.createBooking(
      serviceId: widget.service.id,
      scheduledAt: when,
      note: _noteController.text,
      token: token,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not book')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<BookingsProvider>().loading;
    final ready = _date != null && _time != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Book appointment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.service.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _date == null
                    ? 'Choose date'
                    : 'Date: ${formatBookingDate(_date!)}',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time),
              label: Text(
                _time == null
                    ? 'Choose time'
                    : 'Time: ${_time!.format(context)}',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (!ready || loading) ? null : _confirm,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
