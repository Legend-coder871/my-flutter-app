import 'package:flutter/material.dart';

import 'package:mobile/services/api_client.dart';

void main() {
  runApp(const StudentMarketplaceApp());
}

class StudentMarketplaceApp extends StatelessWidget {
  const StudentMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ConnectionTestScreen(),
    );
  }
}

// Temporary screen that checks the backend is reachable.
class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  final ApiClient _api = ApiClient();
  bool _loading = true;
  bool _connected = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _check();
  }

  // Call GET /health and remember the result.
  Future<void> _check() async {
    setState(() {
      _loading = true;
      _message = '';
    });
    try {
      await _api.get('/health');
      setState(() {
        _connected = true;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _connected = false;
        _message = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _connected ? Icons.check_circle : Icons.error,
                    color: _connected ? Colors.green : Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _connected ? 'Backend connected' : _message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: _connected ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_connected)
                    ElevatedButton(
                      onPressed: _check,
                      child: const Text('Retry'),
                    ),
                ],
              ),
      ),
    );
  }
}
