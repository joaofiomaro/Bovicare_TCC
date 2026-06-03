import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/vet_model.dart';

class VetLocalDataSource {
  static const _boxName = 'vets';

  Box<String> get _box => Hive.box<String>(_boxName);

  Future<List<VetModel>> getAll() async {
    if (_box.isEmpty) await _seed();
    return _box.values
        .map((raw) => VetModel.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  Future<VetModel?> getById(String id) async {
    final raw = _box.get(id);
    if (raw == null) return null;
    return VetModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Popula com veterinários fictícios para demonstração do TCC.
  /// Coordenadas ao redor de Rio Claro, SP (-22.41, -47.56).
  Future<void> _seed() async {
    const seed = [
      VetModel(
        id:               '1',
        name:             'Dr. Carlos Lima',
        crmv:             'CRMV-SP 12345',
        specialties:      ['Clínica geral', 'Reprodução', 'Sanidade'],
        phone:            '+5519988880001',
        whatsapp:         '+5519988880001',
        email:            'carlos.lima@vetclinica.com.br',
        city:             'Rio Claro',
        state:            'SP',
        lat:              -22.3500,
        lng:              -47.5000,
        isAvailable:      true,
        coverageRadiusKm: 40,
      ),
      VetModel(
        id:               '2',
        name:             'Dra. Ana Souza',
        crmv:             'CRMV-SP 67890',
        specialties:      ['Reprodução', 'Sanidade animal'],
        phone:            '+5519988880002',
        whatsapp:         '+5519988880002',
        email:            'ana.souza@vetrepro.com.br',
        city:             'Limeira',
        state:            'SP',
        lat:              -22.4900,
        lng:              -47.6800,
        isAvailable:      true,
        coverageRadiusKm: 50,
      ),
      VetModel(
        id:               '3',
        name:             'Dr. Roberto Neves',
        crmv:             'CRMV-SP 54321',
        specialties:      ['Clínica geral', 'Cirurgia'],
        phone:            '+5519988880003',
        email:            'r.neves@vetcirurgia.com.br',
        city:             'Araras',
        state:            'SP',
        lat:              -22.3570,
        lng:              -47.3840,
        isAvailable:      false,
        coverageRadiusKm: 30,
      ),
      VetModel(
        id:               '4',
        name:             'Dra. Fernanda Castro',
        crmv:             'CRMV-SP 11223',
        specialties:      ['Nutrição animal', 'Clínica geral'],
        phone:            '+5519988880004',
        whatsapp:         '+5519988880004',
        email:            'fernanda@vetnutri.com.br',
        city:             'Piracicaba',
        state:            'SP',
        lat:              -22.7253,
        lng:              -47.6492,
        isAvailable:      true,
        coverageRadiusKm: 60,
      ),
    ];
    for (final v in seed) {
      await _box.put(v.id, jsonEncode(v.toJson()));
    }
  }
}
