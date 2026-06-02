import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/animal_model.dart';

class AnimalLocalDataSource {
  static const _boxName = 'animals';

  Box<String> get _box => Hive.box<String>(_boxName);

  Future<List<AnimalModel>> getAll() async {
    if (_box.isEmpty) await _seed();
    return _box.values
        .map((raw) => AnimalModel.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.earTag.compareTo(b.earTag));
  }

  Future<AnimalModel?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return AnimalModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(AnimalModel model) =>
      _box.put(model.id, jsonEncode(model.toJson()));

  Future<void> delete(String id) => _box.delete(id);

  /// Popula o box com animais demonstrativos na primeira execução.
  Future<void> _seed() async {
    final now = DateTime.now();
    final seed = [
      AnimalModel(id: '1', earTag: '047', name: 'Mimosa',   breed: 'Nelore',   sex: 'female', status: 'pregnant',  birthDateIso: '2022-03-12', weightKg: 384, pregnancyDateIso: DateTime(now.year - 1, 10, 10).toIso8601String()),
      const AnimalModel(id: '2', earTag: '031', name: 'Estrela',  breed: 'Gir',      sex: 'female', status: 'attention', birthDateIso: '2020-01-20', weightKg: 410),
      const AnimalModel(id: '3', earTag: '003', name: 'Touro 01', breed: 'Nelore',   sex: 'male',   status: 'healthy',   birthDateIso: '2021-06-15', weightKg: 620),
      const AnimalModel(id: '4', earTag: '058', name: 'Bela',     breed: 'Gir',      sex: 'female', status: 'sick',      birthDateIso: '2023-02-08', weightKg: 290),
      const AnimalModel(id: '5', earTag: '072', name: 'Pintada',  breed: 'Nelore',   sex: 'female', status: 'healthy',   birthDateIso: '2021-09-30', weightKg: 360),
      AnimalModel(id: '6', earTag: '089', name: 'Aurora',   breed: 'Girolando',sex: 'female', status: 'pregnant',  birthDateIso: '2022-07-04', weightKg: 395, pregnancyDateIso: DateTime(now.year - 1, 8, 20).toIso8601String()),
      const AnimalModel(id: '7', earTag: '012', name: 'Bravo',    breed: 'Brahman',  sex: 'male',   status: 'healthy',   birthDateIso: '2019-04-18', weightKg: 710),
    ];
    for (final a in seed) {
      await _box.put(a.id, jsonEncode(a.toJson()));
    }
  }
}
