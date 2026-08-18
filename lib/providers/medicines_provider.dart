import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';
import '../services/medicine_service.dart';

final medicineServiceProvider = Provider<MedicineService>((ref) => MedicineService());

final medicinesProvider = StreamProvider<List<MedicineModel>>((ref) {
  final service = ref.watch(medicineServiceProvider);
  return service.watchMedicines();
});

final medicinesOnceProvider = FutureProvider<List<MedicineModel>>((ref) async {
  final service = ref.watch(medicineServiceProvider);
  return service.getAllMedicines();
});