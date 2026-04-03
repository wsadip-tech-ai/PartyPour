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
            ),

            // === RESUME CARD ===
            if (hasWizardInProgress)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
class _HeroSection extends StatelessWidget {
  final VoidCallback onStartOrder;
  final VoidCallback onCalculator;

  const _HeroSection({required this.onStartOrder, required this.onCalculator});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_surfaceDark, _darkBg],
        ),
      ),
      child: Stack(
        children: [
          // Gold radial glow
          Positioned(top: -40, right: -40, child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [_gold.withValues(alpha: 0.1), Colors.transparent])),
          )),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tagline badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.1),
                  border: Border.all(color: _gold.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('PREMIUM EVENT BEVERAGES', style: TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                ]),
              ),
              const SizedBox(height: 16),
              // Headline
              RichText(text: const TextSpan(
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _textLight, height: 1.2, fontFamily: 'Inter'),
                children: [
                  TextSpan(text: 'Curate your\n'),
                  TextSpan(text: 'perfect ', style: TextStyle(fontStyle: FontStyle.italic, color: _gold)),
                  TextSpan(text: 'event bar'),
                ],
              )),
              const SizedBox(height: 8),
              const Text('62+ brands, delivered to your celebration', style: TextStyle(color: _muted, fontSize: 13)),
              const SizedBox(height: 20),
              // Action buttons
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onStartOrder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_gold, _goldLight]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: const Center(child: Text('Start Your Order', style: TextStyle(color: _darkBg, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onCalculator,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _surfaceDark,
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('Calculator', style: TextStyle(color: _textLight, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ]),
            ],
          ),
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
