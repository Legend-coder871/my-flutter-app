import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/item.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/items_provider.dart';
import 'package:mobile/screens/services_screen.dart';

// One form used both to list a new item and to edit an existing one.
class ItemFormScreen extends StatefulWidget {
  final Item? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _nameController = TextEditingController(text: it?.name ?? '');
    _descriptionController = TextEditingController(text: it?.description ?? '');
    _categoryController = TextEditingController(text: it?.category ?? '');
    _priceController = TextEditingController(
      text: it == null ? '' : formatPrice(it.price),
    );
    _quantityController = TextEditingController(
      text: it == null ? '1' : '${it.quantity}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Validate and save through ItemsProvider.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<ItemsProvider>();

    final bool ok;
    if (_isEditing) {
      ok = await provider.updateItem(
        id: widget.item!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        token: token,
      );
    } else {
      ok = await provider.createItem(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        token: token,
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not save item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ItemsProvider>().loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit item' : 'Sell an item'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Category is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (v) {
                  final text = (v ?? '').trim();
                  if (text.isEmpty) return 'Price is required';
                  final n = double.tryParse(text);
                  if (n == null || n < 0) return 'Price must be a number >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (v) {
                  final text = (v ?? '').trim();
                  final n = int.tryParse(text);
                  if (n == null || n < 1) {
                    return 'Quantity must be an integer >= 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _save,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Create item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
