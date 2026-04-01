import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) => profile == null
            ? const Center(child: Text('Not logged in'))
            : ListView(padding: const EdgeInsets.all(16), children: [
                CircleAvatar(radius: 40, child: Text((profile.fullName ?? 'U')[0].toUpperCase(), style: const TextStyle(fontSize: 32))),
                const SizedBox(height: 16),
                Card(child: Column(children: [
                  ListTile(leading: const Icon(Icons.person), title: const Text('Name'), subtitle: Text(profile.fullName ?? 'Not set')),
                  ListTile(leading: const Icon(Icons.email), title: const Text('Email'), subtitle: Text(profile.email ?? 'Not set')),
                  ListTile(leading: const Icon(Icons.phone), title: const Text('Phone'), subtitle: Text(profile.phone ?? 'Not set')),
                ])),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async { await ref.read(authServiceProvider).signOut(); if (context.mounted) context.go('/login'); },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ]),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
