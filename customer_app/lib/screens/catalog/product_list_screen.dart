import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/cart_badge.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String subcategoryId;
  const ProductListScreen({super.key, required this.subcategoryId});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String? _originFilter;

  static const _bgColor = Color(0xFF1C1917);
  static const _surfaceColor = Color(0xFF292524);
  static const _goldColor = Color(0xFFCA8A04);
  static const _goldLightColor = Color(0xFFEAB308);
  static const _borderColor = Color(0xFF44403C);
  static const _textPrimary = Color(0xFFFAFAF9);
  static const _textMuted = Color(0xFF78716C);
  static const _localGreen = Color(0xFF4ade80);

  // Generates consistent gradient colors from a string (product name)
  List<Color> _getColors(String seed) {
    final hash = seed.codeUnits.fold(0, (prev, e) => prev + e);
    final palettes = [
      [const Color(0xFF92400E), const Color(0xFF78350F)],
      [const Color(0xFF1E3A5F), const Color(0xFF0F2137)],
      [const Color(0xFF3B1F5E), const Color(0xFF1A0D2E)],
      [const Color(0xFF134E4A), const Color(0xFF0D3330)],
      [const Color(0xFF431407), const Color(0xFF2D0D04)],
    ];
    return palettes[hash % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      productsProvider((
        subcategoryId: widget.subcategoryId,
        origin: _originFilter,
      )),
    );

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Products',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
        actions: const [CartBadge()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _borderColor),
        ),
      ),
      body: Column(
        children: [
          // Origin filter pills
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(
                    label: 'All',
                    isActive: _originFilter == null,
                    onTap: () => setState(() => _originFilter = null),
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Local',
                    isActive: _originFilter == 'local',
                    onTap: () => setState(() => _originFilter = 'local'),
                    activeColor: _localGreen,
                  ),
                  const SizedBox(width: 8),
                  _FilterPill(
                    label: 'Imported',
                    isActive: _originFilter == 'imported',
                    onTap: () => setState(() => _originFilter = 'imported'),
                    activeColor: _goldLightColor,
                  ),
                ],
              ),
            ),
          ),

          // Product grid
          Expanded(
            child: productsAsync.when(
              data: (products) => products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 48, color: _textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No products found',
                            style: TextStyle(color: _textMuted, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final colors = _getColors(product.name);
                        return _ProductGridCard(
                          product: product,
                          gradientColors: colors,
                          onTap: () => context.push('/product/${product.id}'),
                        );
                      },
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: _goldColor,
                  strokeWidth: 2.5,
                ),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Error: $err',
                  style: const TextStyle(color: _textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeColor = const Color(0xFFCA8A04),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.15)
              : const Color(0xFF292524),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : const Color(0xFF44403C),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : const Color(0xFFA8A29E),
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final dynamic product;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ProductGridCard({
    required this.product,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocal = product.origin == 'local';
    final originColor =
        isLocal ? const Color(0xFF4ade80) : const Color(0xFFEAB308);
    final originLabel = isLocal ? 'Local' : 'Imported';

    // Safely get base price
    String priceLabel = '';
    try {
      final firstVariant = product.variants.first;
      priceLabel = 'NPR ${firstVariant.unitPrice.toStringAsFixed(0)}';
    } catch (_) {}

    // Initial letter for placeholder
    final initial =
        product.name.isNotEmpty ? product.name[0].toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: const Color(0xFFCA8A04).withOpacity(0.08),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF292524),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF44403C), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gradient image placeholder
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(11)),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Origin badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: originColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: originColor.withOpacity(0.30), width: 1),
                        ),
                        child: Text(
                          originLabel,
                          style: TextStyle(
                            color: originColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Product name
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFAFAF9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),

                      const Spacer(),

                      // Price
                      if (priceLabel.isNotEmpty)
                        Text(
                          priceLabel,
                          style: const TextStyle(
                            color: Color(0xFFEAB308),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
