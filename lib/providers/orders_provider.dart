import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

final ordersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final service = ref.watch(orderServiceProvider);
  return service.watchOrders();
});