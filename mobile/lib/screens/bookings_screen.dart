import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/bookings_provider.dart';
import 'package:mobile/screens/booking_screen.dart';

// Color used for a booking's status chip.
Color bookingStatusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'confirmed':
      return Colors.green;
    case 'declined':
      return Colors.red;
    case 'cancelled':
      return Colors.grey;
    default:
      return Colors.blueGrey;
  }
}

// The Bookings tab: my bookings and requests received.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load after the first frame so notifyListeners is not called during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token == null) return;
      final provider = context.read<BookingsProvider>();
      provider.loadMine(token);
      provider.loadReceived(token);
    });
  }

  // Change a booking's status, showing any API error.
  Future<void> _changeStatus(int id, String status) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<BookingsProvider>();
    final ok = await provider.updateStatus(id, status, token);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Could not update booking')),
    );
  }

  // Status chip shown on every card.
  Widget _statusChip(String status) {
    return Chip(
      label: Text(status),
      backgroundColor: bookingStatusColor(status),
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  // "My bookings" list.
  Widget _mineList() {
    final provider = context.watch<BookingsProvider>();
    final token = context.watch<AuthProvider>().token;

    if (provider.loading && provider.mine.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.mine.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => provider.loadMine(token ?? ''),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Center(child: Text('You have not booked any appointments yet')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => provider.loadMine(token ?? ''),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.mine.length,
        itemBuilder: (context, i) {
          final b = provider.mine[i];
          final cancellable = b.status == 'pending' || b.status == 'confirmed';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.serviceTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _statusChip(b.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatBookingDate(b.scheduledAt)}  |  '
                    '${formatBookingTime(b.scheduledAt)}',
                  ),
                  if (b.providerName != null)
                    Text('Provider: ${b.providerName}'),
                  if (b.providerPhone != null) Text('Phone: ${b.providerPhone}'),
                  if (cancellable)
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () => _changeStatus(b.id, 'cancelled'),
                        child: const Text('Cancel'),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // "Requests received" list.
  Widget _receivedList() {
    final provider = context.watch<BookingsProvider>();
    final token = context.watch<AuthProvider>().token;

    if (provider.loading && provider.received.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.received.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => provider.loadReceived(token ?? ''),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Center(child: Text('No booking requests yet')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => provider.loadReceived(token ?? ''),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.received.length,
        itemBuilder: (context, i) {
          final b = provider.received[i];
          final isPending = b.status == 'pending';
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.serviceTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _statusChip(b.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatBookingDate(b.scheduledAt)}  |  '
                    '${formatBookingTime(b.scheduledAt)}',
                  ),
                  if (b.customerName != null)
                    Text('Customer: ${b.customerName}'),
                  if (b.customerPhone != null) Text('Phone: ${b.customerPhone}'),
                  if (isPending)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _changeStatus(b.id, 'declined'),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _changeStatus(b.id, 'confirmed'),
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const TabBar(
              tabs: [
                Tab(text: 'My bookings'),
                Tab(text: 'Requests received'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [_mineList(), _receivedList()],
            ),
          ),
        ],
      ),
    );
  }
}
