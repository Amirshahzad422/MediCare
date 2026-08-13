class MedicineModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final String image;
  final bool requiresPrescription;
  final String description;
  final int stock;

  MedicineModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.image,
    required this.requiresPrescription,
    required this.description,
    required this.stock,
  });

  factory MedicineModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MedicineModel(
      id: documentId,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? 'General',
      price: (data['price'] ?? 0).toDouble(),
      image: data['image'] ?? '',
      requiresPrescription: data['requiresPrescription'] ?? false,
      description: data['description'] ?? '',
      stock: (data['stock'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      'image': image,
      'requiresPrescription': requiresPrescription,
      'description': description,
      'stock': stock,
    };
  }
}