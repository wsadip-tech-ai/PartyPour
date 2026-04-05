import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/wizard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/cart_badge.dart';

const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFF78716C);
const _mutedLight = Color(0xFFA8A29E);
const _border = Color(0xFF44403C);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final hasWizardInProgress = wizard.selectedTypeSlugs.isNotEmpty;

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        title: const Text('RaksiChaiyo', style: TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 0.3)),
        actions: [
          // Notification bell
          Consumer(builder: (context, ref, _) {
            final unread = ref.watch(unreadCountProvider);
            return IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                backgroundColor: _gold,
                child: const Icon(Icons.notifications_outlined, color: _muted),
              ),
            );
          }),
          const CartBadge(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HERO SECTION ===
            _HeroSection(
              onStartOrder: () {
                ref.read(wizardProvider.notifier).reset();
                context.push('/wizard/event');
              },
              onCalculator: () => context.push('/calculator'),
              onBrowseCatalog: () => context.push('/category/a1000000-0000-0000-0000-000000000001'),
            ),

            // === RESUME CARD ===
            if (hasWizardInProgress)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _surfaceDark,
                    border: Border.all(color: _gold.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: _gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.replay, color: _gold, size: 20),
                      ),
                      title: const Text('Resume your order', style: TextStyle(fontWeight: FontWeight.w600, color: _textLight, fontSize: 14)),
                      subtitle: Text('${wizard.selectedTypeSlugs.length} types • ${wizard.totalPax} guests', style: const TextStyle(color: _muted, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: _gold),
                      onTap: () => context.push('/wizard/types'),
                    ),
                  ),
                ),
              ),

            // === BROWSE BY TYPE ===
            _SectionHeader(title: 'Browse by Type', actionLabel: 'See all', onAction: () => context.push('/category/a1000000-0000-0000-0000-000000000001')),  // Hard Drinks category
            const SizedBox(height: 8),
            _TypeChips(ref: ref),

            // === POPULAR PICKS ===
            _SectionHeader(title: 'Popular Picks', actionLabel: 'View all', onAction: () => context.push('/wizard/event')),
            const SizedBox(height: 8),
            _PopularProducts(ref: ref),

            // === PROMO CARD ===
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: GestureDetector(
              onTap: () {
                ref.read(wizardProvider.notifier).reset();
                ref.read(wizardProvider.notifier).setEventType('wedding');
                context.push('/wizard/event');
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_gold.withValues(alpha: 0.08), _gold.withValues(alpha: 0.02)]),
                  border: Border.all(color: _gold.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: _gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.celebration, color: _gold, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wedding Season Special', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textLight)),
                          SizedBox(height: 2),
                          Text('Get 10% off on orders above NPR 50,000', style: TextStyle(fontSize: 11, color: _muted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: _gold, size: 20),
                  ],
                ),
              ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Consumer(
        builder: (context, ref, _) {
          final unreadCount = ref.watch(unreadCountProvider);
          return NavigationBar(
            destinations: [
              const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(
                icon: Badge(isLabelVisible: unreadCount > 0, label: Text('$unreadCount'), backgroundColor: _gold, child: const Icon(Icons.receipt_long)),
                label: 'Orders',
              ),
              const NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
            onDestinationSelected: (index) {
              switch (index) {
                case 0: context.go('/home');
                case 1: context.go('/orders');
                case 2: context.go('/profile');
              }
            },
          );
        },
      ),
    );
  }
}

// === HERO SECTION ===
class _HeroSection extends StatefulWidget {
  final VoidCallback onStartOrder;
  final VoidCallback onCalculator;
  final VoidCallback onBrowseCatalog;

  const _HeroSection({required this.onStartOrder, required this.onCalculator, required this.onBrowseCatalog});

  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.25, end: 0.55).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      color: _darkBg,
      child: Column(
        children: [
          // --- Big Hero Card with Circle CTA ---
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (context, child) {
              return GestureDetector(
                onTap: widget.onStartOrder,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: BoxDecoration(
                    color: _surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _gold.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: _glowAnim.value * 0.3),
                        blurRadius: 40,
                        spreadRadius: 0,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.08),
                          border: Border.all(color: _gold.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text("NEPAL'S BEVERAGE CONCIERGE", style: TextStyle(fontSize: 9, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
                      ),
                      const SizedBox(height: 16),
                      // Headline
                      const Text('Plan your event\nbeverages in', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textLight, height: 1.2)),
                      const Text('2 minutes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _gold, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                      const Text('Tell us your guest count and we\'ll recommend\nexactly what you need.', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: _muted, height: 1.5)),
                      const SizedBox(height: 20),
                      // Circle CTA
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFB45309), _gold, _goldLight],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _gold.withValues(alpha: _glowAnim.value),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.celebration, size: 32, color: _darkBg),
                            SizedBox(height: 4),
                            Text('Start Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _darkBg, letterSpacing: 0.3)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Tap to begin', style: TextStyle(fontSize: 10, color: _muted)),
                      const SizedBox(height: 14),
                      // Stats strip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatChip(value: '62+', label: 'brands'),
                          Container(width: 1, height: 20, color: _border, margin: const EdgeInsets.symmetric(horizontal: 16)),
                          _StatChip(value: '5', label: 'step wizard'),
                          Container(width: 1, height: 20, color: _border, margin: const EdgeInsets.symmetric(horizontal: 16)),
                          _StatChip(value: '24hr', label: 'delivery'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // --- Secondary actions row ---
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: widget.onCalculator,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: _surfaceDark,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calculate_outlined, color: _mutedLight, size: 16),
                      SizedBox(width: 6),
                      Text('Calculator', style: TextStyle(color: _mutedLight, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: widget.onBrowseCatalog,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: _surfaceDark,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_outlined, color: _mutedLight, size: 16),
                      SizedBox(width: 6),
                      Text('Browse Catalog', style: TextStyle(color: _mutedLight, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// === SECTION HEADER ===
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textLight)),
        const Spacer(),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text('$actionLabel >', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _gold)),
          ),
      ]),
    );
  }
}

// === TYPE CHIPS ===
class _TypeChips extends StatelessWidget {
  final WidgetRef ref;
  const _TypeChips({required this.ref});

  static const _types = [
    ('Whiskey', Icons.local_bar, 'whiskey'),
    ('Beer', Icons.sports_bar, 'beer-bottle-can'),
    ('Vodka', Icons.local_bar, 'vodka'),
    ('Wine', Icons.wine_bar, 'wine'),
    ('Rum', Icons.local_bar, 'rum'),
    ('Gin', Icons.local_bar, 'gin'),
    ('Brandy', Icons.wine_bar, 'brandy'),
    ('Shots', Icons.local_fire_department, 'shots-specials'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _types.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, icon, slug) = _types[i];
          final isFirst = i == 0;
          return GestureDetector(
            onTap: () async {
              final supabase = Supabase.instance.client;
              final data = await supabase.from('subcategories').select('id').eq('slug', slug).maybeSingle();
              if (data != null && context.mounted) {
                context.push('/products/${data['id']}');
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isFirst ? _gold.withValues(alpha: 0.12) : _surfaceDark,
                border: Border.all(color: isFirst ? _gold.withValues(alpha: 0.3) : _border),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 16, color: isFirst ? _goldLight : _mutedLight),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isFirst ? _goldLight : _mutedLight)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// === STAT CHIP ===
class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _gold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
      ],
    );
  }
}

// === POPULAR PRODUCTS HORIZONTAL SCROLL ===
class _PopularProducts extends StatelessWidget {
  final WidgetRef ref;
  const _PopularProducts({required this.ref});

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    // Show first 6 products from catalog
    return SizedBox(
      height: 200,
      child: categoriesAsync.when(
        data: (_) => _buildProductList(context),
        loading: () => const Center(child: CircularProgressIndicator(color: _gold)),
        error: (_, __) => const Center(child: Text('', style: TextStyle(color: _muted))),
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    // Static popular items for display — these link to the catalog
    final items = [
      _PopularItem('Johnnie Walker', 'Imported', 3200, 'JW', [_gold, _goldLight]),
      _PopularItem('Old Durbar', 'Local', 700, 'OD', [_surfaceDark, const Color(0xFF57534e)]),
      _PopularItem('Tuborg', 'Local', 380, 'TB', [const Color(0xFF2E7D32), const Color(0xFF81C784)]),
      _PopularItem('Absolut', 'Imported', 3500, 'AB', [const Color(0xFF1565C0), const Color(0xFF64B5F6)]),
      _PopularItem('Khukuri Rum', 'Local', 500, 'KR', [const Color(0xFFC62828), const Color(0xFFEF9A9A)]),
    ];

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final item = items[i];
        final isImported = item.origin == 'Imported';
        return GestureDetector(
          onTap: () => context.push('/wizard/event'),
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceDark,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient placeholder with initials
                Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: item.colors),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(item.initials, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(height: 10),
                Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textLight), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isImported ? _goldLight.withValues(alpha: 0.12) : const Color(0xFF4ade80).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(item.origin, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isImported ? _goldLight : const Color(0xFF4ade80))),
                ),
                const Spacer(),
                Text('NPR ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _gold)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PopularItem {
  final String name, origin, initials;
  final double price;
  final List<Color> colors;
  _PopularItem(this.name, this.origin, this.price, this.initials, this.colors);
}
