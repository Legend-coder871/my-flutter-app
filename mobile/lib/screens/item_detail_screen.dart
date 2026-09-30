import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile/models/item.dart';
import 'package:mobile/screens/services_screen.dart';

// Shows the full details of one item and how to reach the seller.
class ItemDetailScreen extends StatelessWidget {
  final Item item;

  const ItemDetailScreen({super.key, required this.item});

  // Copy the seller phone to the clipboard and confirm it.
  Future<void> _copyPhone(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: item.sellerPhone ?? ''));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone copied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = item.sellerPhone;

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '${item.category}  |  Price: ${formatPrice(item.price)}'
              '  |  Quantity: ${item.quantity}',
            ),
            const SizedBox(height: 16),
            Text(item.description),
            const SizedBox(height: 24),
            const Divider(),
            Text('Seller', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(item.sellerName ?? 'Unknown'),
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
