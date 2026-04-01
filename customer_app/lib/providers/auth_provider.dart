import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/profile.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);
final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.watch(supabaseProvider)));
final authStateProvider = StreamProvider<AuthState>((ref) => ref.watch(authServiceProvider).authStateChanges);
final profileProvider = FutureProvider<Profile?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).getProfile();
});
