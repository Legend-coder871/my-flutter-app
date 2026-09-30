import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/login_screen.dart';
import 'package:mobile/screens/register_screen.dart';

// Root screen with the four main tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<String> _labels = [
    'Services',
    'Market',
    'Bookings',
    'Profile',
  ];

  // Open the login screen.
  Future<void> _openLogin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // Open the register screen.
  Future<void> _openRegister() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  // Bookings tab content, guests are asked to log in.
  Widget _bookingsTab(AuthProvider auth) {
    if (!auth.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please log in'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _openLogin, child: const Text('Login')),
          ],
        ),
      );
    }
    return const Center(child: Text('Bookings'));
  }

  // Profile tab content for guests and logged-in users.
  Widget _profileTab(AuthProvider auth) {
    if (!auth.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(onPressed: _openLogin, child: const Text('Login')),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _openRegister,
              child: const Text('Register'),
            ),
          ],
        ),
      );
    }
    final user = auth.user!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(user.email),
          Text(user.phone),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final Widget body;
    switch (_index) {
      case 1:
        body = const Center(child: Text('Market'));
      case 2:
        body = _bookingsTab(auth);
      case 3:
        body = _profileTab(auth);
      default:
        body = const Center(child: Text('Services'));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_labels[_index])),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
