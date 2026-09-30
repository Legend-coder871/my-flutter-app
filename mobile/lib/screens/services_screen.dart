import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/services_provider.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/service_detail_screen.dart';
import 'package:mobile/screens/service_form_screen.dart';

// Format a price without a trailing .0 for whole numbers.
String formatPrice(double price) {
  return price == price.roundToDouble()
      ? price.toStringAsFixed(0)
      : price.toString();
}

// The Services tab: search, list of services and an offer button.
class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Load after the first frame so notifyListeners is not called during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ServicesProvider>().loadServices();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Run a search for the text currently in the search field.
  void _search() {
    _query = _searchController.text.trim();
    context.read<ServicesProvider>().loadServices(query: _query);
  }

  // Clear the search and show all services again.
  void _clearSearch() {
    _searchController.clear();
    _query = '';
    context.read<ServicesProvider>().loadServices();
  }

  // Open the offer form, or the login screen for guests.
  void _offerService() {
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            loggedIn ? const ServiceFormScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServicesProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _offerService,
        icon: const Icon(Icons.add),
        label: const Text('Offer a service'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Search services',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: provider.loading && provider.services.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : provider.services.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 160),
                          Center(child: Text('No services found')),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            provider.loadServices(query: _query),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: provider.services.length,
                          itemBuilder: (context, i) {
                            final s = provider.services[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: ListTile(
                                title: Text(s.title),
                                subtitle: Text(
                                  '${s.category}  |  Price: ${formatPrice(s.price)}'
                                  '${s.providerName == null ? '' : '\n${s.providerName}'}',
                                ),
                                isThreeLine: s.providerName != null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceDetailScreen(
                                      service: s,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
