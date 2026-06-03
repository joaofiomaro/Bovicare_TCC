/// Catálogo de vacinas com regras de carência e intervalo de reforço.
/// Valores baseados nas normas sanitárias do MAPA (Ministério da Agricultura).
abstract final class VaccineInfo {
  static const List<String> vaccines = [
    'Febre Aftosa',
    'Brucelose',
    'Raiva',
    'IBR / BVD',
    'Carbúnculo',
    'Outra',
  ];

  static const List<String> doses = [
    'Dose única',
    '1ª dose',
    '2ª dose',
    'Reforço anual',
  ];

  /// Dias de carência para abate/leite após aplicação.
  static int quarantineDaysFor(String vaccine) => switch (vaccine) {
    'Febre Aftosa' => 21,
    'Brucelose'    => 0,
    'Raiva'        => 0,
    'IBR / BVD'    => 21,
    'Carbúnculo'   => 21,
    _              => 30,
  };

  /// Data estimada para a próxima dose com base no tipo aplicado.
  static DateTime? nextDoseFor(DateTime date, String dose) => switch (dose) {
    '1ª dose'       => date.add(const Duration(days: 30)),
    'Dose única'    => date.add(const Duration(days: 365)),
    '2ª dose'       => date.add(const Duration(days: 365)),
    'Reforço anual' => date.add(const Duration(days: 365)),
    _               => null,
  };
}
