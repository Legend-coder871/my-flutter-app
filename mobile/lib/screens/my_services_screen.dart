import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/services_provider.dart';
import 'package:mobile/screens/service_form_screen.dart';
import 'package:mobile/screens/services_screen.dart';

// Lists the logged-in user's services with edit and delete actions.
class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  @override
  void initState() {
    super.initState();
    // Load after the first frame so notifyListeners is not called during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<ServicesProvider>().loadMyServices(token);
      }
    });
  }

  // Ask for confirmation, then delete the service.
  Future<void> _confirmDelete(int id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text('Delete "$title"? This cannot be undone.'),
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
    final provider = context.read<ServicesProvider>();
    final ok = await provider.deleteService(id, token ?? '');
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not delete service')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServicesProvider>();
    final token = context.watch<AuthProvider>().token;

    final Widget body;
    if (provider.loading && provider.myServices.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.myServices.isEmpty) {
      body = const Center(child: Text('You have not offered any services yet'));
    } else {
      body = ListView.builder(
        itemCount: provider.myServices.length,
        itemBuilder: (context, i) {
          final s = provider.myServices[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              title: Text(s.title),
              subtitle: Text(
                '${s.category}  |  Price: ${formatPrice(s.price)}',
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
                        builder: (_) => ServiceFormScreen(service: s),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(s.id, s.title),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My services')),
      floatingActionButton: FloatingActionButton(
        onPressed: token == null
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ServiceFormScreen(),
                  ),
                ),
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}
