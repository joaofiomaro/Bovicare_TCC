import '../models/vet_model.dart';

/// Veterinários de demonstração para o TCC (ids `demo-*`, exibidos com o selo
/// "Demonstração"). Dados estáticos — coordenadas ao redor de Rio Claro, SP.
class VetInMemoryDataSource {
  static const List<VetModel> _vets = [
    VetModel(
      id:               'demo-1',
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
      id:               'demo-2',
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
      id:               'demo-3',
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
      id:               'demo-4',
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

  Future<List<VetModel>> getAll() async => _vets;

  Future<VetModel?> getById(String id) async {
    final matches = _vets.where((v) => v.id == id);
    return matches.isEmpty ? null : matches.first;
  }
}
