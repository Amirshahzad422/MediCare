class OrderItem {
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 1) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'quantity': quantity};
  }
}

class OrderModel {
  final String id;
  final String patientId;
  final String orderNo;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String address;
  final String paymentMethod;
  final String status;
  final DateTime? createdAt;

  static const List<String> statusFlow = ['Placed', 'Packed', 'Shipped', 'Delivered'];

  OrderModel({
    required this.id,
    required this.patientId,
    required this.orderNo,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.address,
    required this.paymentMethod,
    required this.status,
    this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> data, String documentId) {
    return OrderModel(
      id: documentId,
      patientId: data['patientId'] ?? '',
      orderNo: data['orderNo'] ?? documentId,
      items: (data['items'] as List?)
              ?.map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      address: data['address'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'Card',
      status: data['status'] ?? 'Placed',
      createdAt: (data['createdAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'orderNo': orderNo,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'address': address,
      'paymentMethod': paymentMethod,
      'status': status,
    };
  }
}