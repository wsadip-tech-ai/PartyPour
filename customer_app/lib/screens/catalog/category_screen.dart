import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/cart_badge.dart';

class CategoryScreen extends ConsumerWidget {
  final String categoryId;
  const CategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider(categoryId));
    return Scaffold(
      appBar: AppBar(title: const Text('Select Type'), actions: const [CartBadge()]),
      body: subcategoriesAsync.when(
        data: (subcategories) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: subcategories.length,
          itemBuilder: (context, index) {
            final sub = subcategories[index];
            return Card(child: ListTile(title: Text(sub.name), trailing: const Icon(Icons.chevron_right), onTap: () => context.push('/products/${sub.id}')));
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
