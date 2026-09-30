import 'package:flutter/foundation.dart';

import 'package:mobile/models/item.dart';
import 'package:mobile/services/api_client.dart';

// Loads and mutates items, including the "Item not in market" search.
class ItemsProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<Item> _items = [];
  List<Item> _myItems = [];
  List<Item> _searchResults = [];
  bool _searchActive = false;
  bool? _found;
  String? _message;
  String _query = '';
  bool _loading = false;
  String? _error;
  bool _myLoaded = false;

  List<Item> get items => _items;
  List<Item> get myItems => _myItems;
  List<Item> get searchResults => _searchResults;
  bool get searchActive => _searchActive;
  bool? get found => _found;
  String? get message => _message;
  bool get loading => _loading;
  String? get error => _error;

  // Load all available items.
  Future<void> loadItems() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.get('/items') as List<dynamic>;
      _items =
          data.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  // Search available items; stores the API's found flag and message.
  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      clearSearch();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api
          .get('/items/search?q=${Uri.encodeQueryComponent(q)}')
          as Map<String, dynamic>;
      _searchResults = (data['results'] as List<dynamic>)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
      _found = data['found'] as bool;
      _message = data['message'] as String?;
      _query = q;
      _searchActive = true;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  // Leave search mode and show the full list again.
  void clearSearch() {
    _searchActive = false;
    _found = null;
    _message = null;
    _searchResults = [];
    _query = '';
    notifyListeners();
  }

  // Load the logged-in user's own items.
  Future<void> loadMyItems(String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data =
          await _api.get('/items/mine', token: token) as List<dynamic>;
      _myItems =
          data.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
      _myLoaded = true;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  // Create an item and refresh the public list (which joins the seller).
  Future<bool> createItem({
    required String name,
    required String description,
    required String category,
    required double price,
    required int quantity,
    required String token,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.post(
        '/items',
        body: {
          'name': name,
          'description': description,
          'category': category,
          'price': price,
          'quantity': quantity,
        },
        token: token,
      ) as Map<String, dynamic>;
      final item = Item.fromJson(data);
      if (_myLoaded) {
        _myItems = [item, ..._myItems];
      }
      await loadItems();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // Update an item in place, then refresh an active search.
  Future<bool> updateItem({
    required int id,
    String? name,
    String? description,
    String? category,
    double? price,
    int? quantity,
    bool? isAvailable,
    required String token,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (category != null) body['category'] = category;
      if (price != null) body['price'] = price;
      if (quantity != null) body['quantity'] = quantity;
      if (isAvailable != null) body['is_available'] = isAvailable;
      final data = await _api
          .put('/items/$id', body: body, token: token)
          as Map<String, dynamic>;
      final updated = Item.fromJson(data);
      _myItems = [
        for (final it in _myItems) it.id == id ? _merge(it, updated) : it,
      ];
      if (!updated.isAvailable) {
        // The public list only contains available items.
        _items = _items.where((it) => it.id != id).toList();
      } else {
        _items = [
          for (final it in _items) it.id == id ? _merge(it, updated) : it,
        ];
      }
      if (_searchActive) {
        // Re-run the search so results match the server exactly.
        await search(_query);
      }
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

  // Delete an item from the server and all local lists.
  Future<bool> deleteItem(int id, String token) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.delete('/items/$id', token: token);
      _items = _items.where((it) => it.id != id).toList();
      _myItems = _myItems.where((it) => it.id != id).toList();
      if (_searchActive) {
        await search(_query);
      }
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

  // The update response has no seller join, so keep the old seller info.
  Item _merge(Item old, Item updated) {
    return updated.copyWith(
      sellerName: updated.sellerName ?? old.sellerName,
      sellerPhone: updated.sellerPhone ?? old.sellerPhone,
    );
  }
}
