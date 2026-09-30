import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/item.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/items_provider.dart';
import 'package:mobile/screens/item_detail_screen.dart';
import 'package:mobile/screens/item_form_screen.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/services_screen.dart';

// The Market tab: search for items and browse what is available.
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load after the first frame so notifyListeners is not called during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ItemsProvider>().loadItems();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Run the search and show any API error.
  Future<void> _search() async {
    final provider = context.read<ItemsProvider>();
    await provider.search(_searchController.text);
    if (!mounted || provider.error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error!)),
    );
  }

  // Clear the search box and go back to the full list.
  void _clearSearch() {
    _searchController.clear();
    context.read<ItemsProvider>().clearSearch();
  }

  // Open the item form, or the login screen for guests.
  void _sellItem() {
    final loggedIn = context.read<AuthProvider>().isLoggedIn;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            loggedIn ? const ItemFormScreen() : const LoginScreen(),
      ),
    );
  }

  // One card showing an item's name, price and seller.
  Widget _itemCard(Item item, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(item.name),
        subtitle: Text(
          'Price: ${formatPrice(item.price)}'
          '${item.sellerName == null ? '' : '\n${item.sellerName}'}',
        ),
        isThreeLine: item.sellerName != null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemsProvider>();

    Widget body;
    if (provider.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.searchActive && provider.found == false) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              provider.message ?? 'Item not in market',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              child: const Text('Clear search'),
            ),
          ],
        ),
      );
    } else {
      final list = provider.searchActive
          ? provider.searchResults
          : provider.items;
      body = list.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Center(child: Text('No items available')),
              ],
            )
          : RefreshIndicator(
              onRefresh: () => provider.searchActive
                  ? provider.search(_searchController.text)
                  : provider.loadItems(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, i) => _itemCard(
                  list[i],
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(item: list[i]),
                    ),
                  ),
                ),
              ),
            );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _sellItem,
        icon: const Icon(Icons.add),
        label: const Text('Sell an item'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                labelText: 'Search for an item',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
