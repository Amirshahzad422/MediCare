import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<OrderModel?> placeOrder({
    required List<OrderItem> items,
    required double subtotal,
    required double discount,
    required double total,
    required String address,
    required String paymentMethod,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final now = DateTime.now();
      final orderNo =
          'MC-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';

      final docRef = await _db.collection('orders').add({
        'patientId': user.uid,
        'patientName': user.displayName ?? 'Patient',
        'orderNo': orderNo,
        'items': items.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'address': address,
        'paymentMethod': paymentMethod,
        'status': 'Placed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final doc = await docRef.get();
      return OrderModel.fromMap(doc.data() ?? {}, doc.id);
    } catch (e) {
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> watchOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('orders')
        .where('patientId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aAt = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1900);
        final bAt = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(1900);
        return bAt.compareTo(aAt);
      });
      return list;
    });
  }
}