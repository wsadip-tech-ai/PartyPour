import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import 'auth_provider.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService(ref.watch(supabaseProvider)));
final orderHistoryProvider = FutureProvider<List<Order>>((ref) => ref.watch(orderServiceProvider).getOrderHistory());
final orderDetailProvider = FutureProvider.family<Order, String>((ref, orderId) => ref.watch(orderServiceProvider).getOrder(orderId));
