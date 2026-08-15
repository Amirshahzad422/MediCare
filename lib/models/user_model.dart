class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final int role;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }
}