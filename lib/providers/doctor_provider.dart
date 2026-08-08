import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/doctor_service.dart';
import '../models/doctor_model.dart';

final doctorServiceProvider = Provider<DoctorService>((ref) => DoctorService());

final doctorsListProvider = FutureProvider<List<DoctorModel>>((ref) async {
  final doctorService = ref.read(doctorServiceProvider);
  return await doctorService.getAllDoctors();
});