import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = Provider.of<SupabaseService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Test Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text(
              'Application is working!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'User: ${supabaseService.currentUser?.email ?? "No user"}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Authenticated: ${supabaseService.isAuthenticated}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                supabaseService.signOut();
              },
              child: const Text('Logout'),
            ),
            ElevatedButton(
              onPressed: () {
                // Test login
                supabaseService.signIn(
                  email: 'test@example.com',
                  password: 'password',
                );
              },
              child: const Text('Test Login'),
            ),
          ],
        ),
      ),
    );
  }
}
