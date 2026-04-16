import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/profile.dart';

const _darkBg = Color(0xFF1C1917);
const _surfaceDark = Color(0xFF292524);
const _gold = Color(0xFFCA8A04);
const _goldLight = Color(0xFFEAB308);
const _textLight = Color(0xFFFAFAF9);
const _muted = Color(0xFFA8A29E);
const _mutedDark = Color(0xFF78716C);
const _border = Color(0xFF44403C);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textLight),
        ),
        iconTheme: const IconThemeData(color: _textLight),
      ),
      body: profileAsync.when(
        data: (profile) => profile == null
            ? const Center(child: Text('Not logged in', style: TextStyle(color: _muted)))
            : _ProfileBody(profile: profile),
        loading: () => const Center(child: CircularProgressIndicator(color: _gold)),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: _muted))),
      ),
      bottomNavigationBar: Consumer(builder: (context, ref, _) {
        final unread = ref.watch(unreadCountProvider);
        return NavigationBar(
          backgroundColor: _surfaceDark,
          indicatorColor: _gold.withValues(alpha: 0.18),
          destinations: [
            const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
            NavigationDestination(
              icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), backgroundColor: _gold, child: const Icon(Icons.receipt_long_outlined)),
              selectedIcon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), backgroundColor: _gold, child: const Icon(Icons.receipt_long_rounded)),
              label: 'Orders',
            ),
            const NavigationDestination(icon: Icon(Icons.person_outlined), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
          selectedIndex: 2,
          onDestinationSelected: (i) {
            switch (i) {
              case 0: context.go('/home');
              case 1: context.go('/orders');
            }
          },
        );
      }),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final Profile profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderHistoryProvider);
    final orderCount = ordersAsync.whenOrNull(data: (orders) => orders.length) ?? 0;
    final eventCount = ordersAsync.whenOrNull(data: (orders) => orders.map((o) => o.eventType).where((e) => e != null).toSet().length) ?? 0;

    final initial = (profile.fullName ?? profile.email ?? 'U')[0].toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // Avatar
          Center(
            child: Column(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [_gold, _goldLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: _gold.withValues(alpha: 0.40), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: Text(initial, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: _darkBg, height: 1))),
                ),
                const SizedBox(height: 14),
                Text(profile.fullName ?? 'No Name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textLight)),
                const SizedBox(height: 4),
                Text(profile.email ?? 'No email', style: const TextStyle(fontSize: 13, color: _muted)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats
          Row(
            children: [
              _StatCard(label: 'Orders', value: '$orderCount'),
              const SizedBox(width: 10),
              _StatCard(label: 'Events', value: '$eventCount'),
              const SizedBox(width: 10),
              const _StatCard(label: 'Points', value: '0'),
            ],
          ),

          const SizedBox(height: 24),

          // Account section
          const _SectionLabel(label: 'ACCOUNT'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: _surfaceDark, borderRadius: BorderRadius.circular(13), border: Border.all(color: _border, width: 0.8)),
            child: Column(
              children: [
                _EditableInfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Name',
                  value: profile.fullName ?? 'Not set',
                  onTap: () => _showEditDialog(context, ref, 'Full Name', profile.fullName ?? '', (val) async {
                    await ref.read(authServiceProvider).updateProfile(fullName: val);
                    ref.invalidate(profileProvider);
                  }),
                  isFirst: true,
                ),
                _Divider(),
                _InfoRow(icon: Icons.email_outlined, label: 'Email', value: profile.email ?? 'Not set'),
                _Divider(),
                _EditableInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: profile.phone ?? 'Not set',
                  onTap: () => _showEditDialog(context, ref, 'Phone', profile.phone ?? '', (val) async {
                    await ref.read(authServiceProvider).updateProfile(phone: val);
                    ref.invalidate(profileProvider);
                  }, keyboardType: TextInputType.phone),
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Support section
          const _SectionLabel(label: 'SUPPORT'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: _surfaceDark, borderRadius: BorderRadius.circular(13), border: Border.all(color: _border, width: 0.8)),
            child: Column(
              children: [
                _ActionRow(icon: Icons.chat_bubble_outline_rounded, label: 'Chat with us', isFirst: true, onTap: () => context.push('/chat')),
                _Divider(),
                _ActionRow(icon: Icons.info_outline_rounded, label: 'About PartyPour', isLast: true, onTap: () => _showAboutDialog(context)),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Sign Out
          GestureDetector(
            onTap: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.60), width: 1.2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, String field, String currentValue, Future<void> Function(String) onSave, {TextInputType? keyboardType}) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $field', style: const TextStyle(color: _textLight, fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboardType,
          style: const TextStyle(color: _textLight, fontSize: 16),
          decoration: InputDecoration(
            filled: true, fillColor: _darkBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: _mutedDark))),
          TextButton(
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                await onSave(val);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: _gold, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.local_bar_rounded, color: _gold, size: 24),
            SizedBox(width: 10),
            Text('PartyPour', style: TextStyle(color: _textLight, fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: TextStyle(color: _muted, fontSize: 13)),
            SizedBox(height: 12),
            Text(
              'PartyPour is Nepal\'s premier event beverage platform. We help you plan, estimate, and order the perfect drinks for any celebration.',
              style: TextStyle(color: _textLight, fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 12),
            Text('Based in Kathmandu, Nepal', style: TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: _gold))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: _surfaceDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border, width: 0.8)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _gold)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 11, color: _mutedDark)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _gold, letterSpacing: 1.0));
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _gold),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: _mutedDark)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, color: _textLight, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 14, color: _mutedDark),
        ],
      ),
    );
  }
}

class _EditableInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _EditableInfoRow({required this.icon, required this.label, required this.value, required this.onTap, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _gold),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: _mutedDark)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 13, color: _textLight, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 14, color: _gold),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ActionRow({required this.icon, required this.label, required this.onTap, this.isFirst = false, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _gold),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: _textLight, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _mutedDark),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 0.6, color: _border, margin: const EdgeInsets.symmetric(horizontal: 16));
  }
}
