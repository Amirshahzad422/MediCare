import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';
import '../models/order_model.dart';

class CartItem {
  final MedicineModel medicine;
  int quantity;

  CartItem({required this.medicine, required this.quantity});

  double get lineTotal => medicine.price * quantity;

  Map<String, dynamic> toOrderItem() {
    return {
      'name': medicine.name,
      'price': medicine.price,
      'quantity': quantity,
    };
  }
}

class CartNotifier extends Notifier<List<CartItem>> {
  static const String promoCode = 'MEDICARE10';
  static const double promoDiscount = 10.0;

  @override
  List<CartItem> build() => [];

  void add(MedicineModel medicine, {int qty = 1}) {
    final index = state.indexWhere((item) => item.medicine.id == medicine.id);
    if (index >= 0) {
      state = [
        for (var i = 0; i < state.length; i++)
          if (i == index) CartItem(medicine: state[i].medicine, quantity: state[i].quantity + qty) else state[i],
      ];
    } else {
      state = [...state, CartItem(medicine: medicine, quantity: qty)];
    }
  }

  void increment(String medicineId) {
    state = [
      for (final item in state)
        if (item.medicine.id == medicineId)
          CartItem(medicine: item.medicine, quantity: item.quantity + 1)
        else
          item,
    ];
  }

  void decrement(String medicineId) {
    state = [
      for (final item in state)
        if (item.medicine.id == medicineId)
          item.quantity > 1
              ? CartItem(medicine: item.medicine, quantity: item.quantity - 1)
              : item
        else
          item,
    ];
  }

  void remove(String medicineId) {
    state = state.where((item) => item.medicine.id != medicineId).toList();
  }

  void updateQuantity(String medicineId, int newQuantity) {
    if (newQuantity <= 0) {
      remove(medicineId);
      return;
    }
    state = [
      for (final item in state)
        if (item.medicine.id == medicineId)
          CartItem(medicine: item.medicine, quantity: newQuantity)
        else
          item,
    ];
  }

  void clear() => state = [];

  bool get isEmpty => state.isEmpty;

  double get subtotal => state.fold(0, (sum, item) => sum + item.lineTotal);

  int get totalItems => state.fold(0, (sum, item) => sum + item.quantity);

  List<OrderItem> toOrderItems() {
    return state
        .map((item) => OrderItem(name: item.medicine.name, price: item.medicine.price, quantity: item.quantity))
        .toList();
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);