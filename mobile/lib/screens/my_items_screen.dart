import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/items_provider.dart';
import 'package:mobile/screens/item_form_screen.dart';
import 'package:mobile/screens/services_screen.dart';

// Lists the logged-in user's items with edit, delete and availability.
class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  @override
  void initState() {
    super.initState();
    // Load after the first frame so notifyListeners is not called during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<ItemsProvider>().loadMyItems(token);
      }
    });
  }

  // Ask for confirmation, then delete the item.
  Future<void> _confirmDelete(int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token;
    final provider = context.read<ItemsProvider>();
    final ok = await provider.deleteItem(id, token ?? '');
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not delete item')),
      );
    }
  }

  // Toggle the item between available and unavailable.
  Future<void> _toggleAvailable(int id, bool value) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<ItemsProvider>();
    final ok = await provider.updateItem(
      id: id,
      isAvailable: value,
      token: token,
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Could not update item')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemsProvider>();
    final token = context.watch<AuthProvider>().token;

    final Widget body;
    if (provider.loading && provider.myItems.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.myItems.isEmpty) {
      body = const Center(child: Text('You have not listed any items yet'));
    } else {
      body = ListView.builder(
        itemCount: provider.myItems.length,
        itemBuilder: (context, i) {
          final it = provider.myItems[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(it.name),
              subtitle: Text(
                '${it.category}  |  Price: ${formatPrice(it.price)}'
                '  |  Qty: ${it.quantity}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemFormScreen(item: it),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(it.id, it.name),
                  ),
                  Switch(
                    value: it.isAvailable,
                    onChanged: (v) => _toggleAvailable(it.id, v),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My items')),
      floatingActionButton: FloatingActionButton(
        onPressed: token == null
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ItemFormScreen()),
                ),
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}
