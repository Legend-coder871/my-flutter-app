import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/service.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/services_provider.dart';
import 'package:mobile/screens/services_screen.dart';

// One form used both to offer a new service and to edit an existing one.
class ServiceFormScreen extends StatefulWidget {
  final Service? service;

  const ServiceFormScreen({super.key, this.service});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _titleController = TextEditingController(text: s?.title ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _categoryController = TextEditingController(text: s?.category ?? '');
    _priceController = TextEditingController(
      text: s == null ? '' : formatPrice(s.price),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Validate and save through ServicesProvider.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    final provider = context.read<ServicesProvider>();
    final price = double.parse(_priceController.text.trim());

    final bool ok;
    if (_isEditing) {
      ok = await provider.updateService(
        id: widget.service!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        price: price,
        token: token,
      );
    } else {
      ok = await provider.createService(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        price: price,
        token: token,
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Could not save service')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<ServicesProvider>().loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit service' : 'Offer a service'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Title is required' : null,
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _save,
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Create service'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
