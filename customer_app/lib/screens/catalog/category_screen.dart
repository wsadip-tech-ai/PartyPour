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
      backgroundColor: const Color(0xFF1C1917),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1917),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Select Type',
          style: TextStyle(
            color: Color(0xFFFAFAF9),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFAFAF9)),
        actions: const [CartBadge()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF44403C)),
        ),
      ),
      body: subcategoriesAsync.when(
        data: (subcategories) => subcategories.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 48, color: const Color(0xFF78716C)),
                    const SizedBox(height: 12),
                    const Text(
                      'No types available',
                      style: TextStyle(color: Color(0xFF78716C), fontSize: 15),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: subcategories.length,
                itemBuilder: (context, index) {
                  final sub = subcategories[index];
                  return _SubcategoryCard(
                    subcategory: sub,
                    onTap: () => context.push('/products/${sub.id}'),
                  );
                },
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFCA8A04),
            strokeWidth: 2.5,
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Color(0xFFA8A29E)),
          ),
        ),
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  final dynamic subcategory;
  final VoidCallback onTap;

  const _SubcategoryCard({required this.subcategory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFFCA8A04).withOpacity(0.08),
          highlightColor: const Color(0xFFCA8A04).withOpacity(0.04),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF292524),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF44403C), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Gold icon circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCA8A04).withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFCA8A04).withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_bar_outlined,
                    color: Color(0xFFCA8A04),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),

                // Name + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subcategory.name,
                        style: const TextStyle(
                          color: Color(0xFFFAFAF9),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subcategory.description != null &&
                          (subcategory.description as String).isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subcategory.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF78716C),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Gold count badge (if productCount available)
                if (subcategory.productCount != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCA8A04).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFCA8A04).withOpacity(0.30),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${subcategory.productCount}',
                      style: const TextStyle(
                        color: Color(0xFFEAB308),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF78716C),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
