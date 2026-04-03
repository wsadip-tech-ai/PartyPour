import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
  } catch (_) {
    // Supabase init may fail without internet — app will retry on login
  }
  runApp(const ProviderScope(child: RaksiChaiyoApp()));
}

class RaksiChaiyoApp extends ConsumerWidget {
  const RaksiChaiyoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'RaksiChaiyo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCA8A04),
          primary: const Color(0xFF1C1917),
          secondary: const Color(0xFFCA8A04),
          surface: const Color(0xFFFAFAF9),
          onPrimary: const Color(0xFFFAFAF9),
          onSecondary: const Color(0xFF1C1917),
          onSurface: const Color(0xFF0C0A09),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAF9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1917),
          foregroundColor: Color(0xFFFAFAF9),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE7E5E4)),
          ),
          color: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFCA8A04),
            foregroundColor: const Color(0xFF1C1917),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1C1917),
            side: const BorderSide(color: Color(0xFFCA8A04)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1C1917),
          indicatorColor: const Color(0xFFCA8A04).withValues(alpha: 0.15),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFFCA8A04));
            }
            return const IconThemeData(color: Color(0xFF78716C));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Color(0xFFCA8A04), fontSize: 12, fontWeight: FontWeight.w600);
            }
            return const TextStyle(color: Color(0xFF78716C), fontSize: 12);
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCA8A04), width: 2)),
          filled: true,
          fillColor: Colors.white,
        ),
        chipTheme: ChipThemeData(
          selectedColor: const Color(0xFFCA8A04).withValues(alpha: 0.15),
          backgroundColor: const Color(0xFFF5F5F4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: const BorderSide(color: Color(0xFFE7E5E4)),
          labelStyle: const TextStyle(fontSize: 13),
        ),
        dividerTheme: const DividerThemeData(color: Color(0xFFE7E5E4)),
      ),
      routerConfig: router,
    );
  }
}
