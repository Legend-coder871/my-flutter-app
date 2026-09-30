import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile/models/service.dart';
import 'package:mobile/screens/services_screen.dart';

// Shows the full details of one service.
class ServiceDetailScreen extends StatelessWidget {
  final Service service;

  const ServiceDetailScreen({super.key, required this.service});

  // Copy the provider phone to the clipboard and confirm it.
  Future<void> _copyPhone(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: service.providerPhone ?? ''));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = service.providerPhone;

    return Scaffold(
      appBar: AppBar(title: Text(service.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              service.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('${service.category}  |  Price: ${formatPrice(service.price)}'),
            const SizedBox(height: 16),
            Text(service.description),
            const SizedBox(height: 24),
            const Divider(),
            Text(
              'Provider: ${service.providerName ?? 'Unknown'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Phone: ${phone ?? 'Not available'}'),
            const SizedBox(height: 16),
            if (phone != null && phone.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => _copyPhone(context),
                icon: const Icon(Icons.copy),
                label: const Text('Copy phone'),
              ),
          ],
        ),
      ),
    );
  }
}
