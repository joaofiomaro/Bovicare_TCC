import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/vaccination_model.dart';

class VaccinationLocalDataSource {
  static const _boxName = 'vaccinations';

  Box<String> get _box => Hive.box<String>(_boxName);

  Future<List<VaccinationModel>> getAll() async {
    return _box.values
        .map((raw) =>
            VaccinationModel.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));
  }

  Future<List<VaccinationModel>> getByAnimal(String animalId) async {
    final records = _box.values
        .map((raw) =>
            VaccinationModel.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .where((m) => m.animalId == animalId)
        .toList()
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso)); // mais recente primeiro
    return records;
  }

  Future<void> save(VaccinationModel model) =>
      _box.put(model.id, jsonEncode(model.toJson()));

  Future<void> delete(String id) => _box.delete(id);
}
