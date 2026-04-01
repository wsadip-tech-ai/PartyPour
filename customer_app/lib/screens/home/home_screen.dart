import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/cart_badge.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('RaksiChaiyo'), actions: const [CartBadge()]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchBar(hintText: 'Search beverages...', leading: const Icon(Icons.search), onSubmitted: (query) {}),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => context.push('/planner'), icon: const Icon(Icons.event), label: const Text('Plan My Event'))),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: categoriesAsync.when(
              data: (categories) => GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/category/${category.id}'),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_categoryIcon(category.slug), size: 48, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(category.name, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/home');
            case 1: context.go('/orders');
            case 2: context.go('/profile');
          }
        },
      ),
    );
  }

  IconData _categoryIcon(String slug) => switch (slug) {
    'hard-drinks' => Icons.local_bar,
    'soft-drinks' => Icons.local_cafe,
    'mixers-add-ons' => Icons.blender,
    'equipment-rental' => Icons.build,
    _ => Icons.local_drink,
  };
}
