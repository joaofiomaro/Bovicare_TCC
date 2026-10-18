/// Preferências de alertas do produtor — `users/{uid}/settings/alerts`.
class AlertSettings {
  const AlertSettings({
    this.leadDays = 30,
    this.vaccines = true,
    this.withdrawal = true,
    this.births = true,
  });

  factory AlertSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AlertSettings();
    final lead = (map['leadDays'] as num?)?.toInt() ?? 30;
    return AlertSettings(
      leadDays:   leadOptions.contains(lead) ? lead : 30,
      vaccines:   (map['vaccines'] as bool?) ?? true,
      withdrawal: (map['withdrawal'] as bool?) ?? true,
      births:     (map['births'] as bool?) ?? true,
    );
  }

  /// Antecedências oferecidas na tela (dias).
  static const List<int> leadOptions = [7, 15, 30, 60];

  /// Com quantos dias de antecedência avisar (vacina/parto).
  final int leadDays;

  /// Próximas doses e doses atrasadas.
  final bool vaccines;

  /// Animais em carência (vacinas e tratamentos).
  final bool withdrawal;

  /// Partos previstos.
  final bool births;

  AlertSettings copyWith({
    int? leadDays,
    bool? vaccines,
    bool? withdrawal,
    bool? births,
  }) =>
      AlertSettings(
        leadDays:   leadDays ?? this.leadDays,
        vaccines:   vaccines ?? this.vaccines,
        withdrawal: withdrawal ?? this.withdrawal,
        births:     births ?? this.births,
      );

  Map<String, dynamic> toMap() => {
        'leadDays':   leadDays,
        'vaccines':   vaccines,
        'withdrawal': withdrawal,
        'births':     births,
      };
}

/// Finalidades de tratamento de dados que dependem de consentimento (LGPD,
/// art. 7º, I). As demais (conta, rebanho, chamados) são necessárias à
/// execução do serviço contratado pelo próprio titular (art. 7º, V).
enum ConsentPurpose {
  /// Usar a localização do aparelho para ordenar veterinários e marcar a
  /// fazenda em chamados.
  location,
}

extension ConsentPurposeX on ConsentPurpose {
  String get title => switch (this) {
        ConsentPurpose.location => 'Localização do aparelho',
      };

  String get description => switch (this) {
        ConsentPurpose.location =>
          'Usada somente no aparelho para mostrar os veterinários mais '
          'próximos e, se você escolher, marcar a fazenda num chamado. '
          'Revogando, o app usa uma região de referência.',
      };
}

/// Registro de consentimentos — `users/{uid}/settings/consents`.
/// Cada finalidade guarda a decisão e o momento (prova do consentimento).
class ConsentSettings {
  const ConsentSettings({this.decisions = const {}});

  factory ConsentSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ConsentSettings();
    final decisions = <ConsentPurpose, ConsentDecision>{};
    for (final purpose in ConsentPurpose.values) {
      final raw = map[purpose.name];
      if (raw is Map<String, dynamic>) {
        decisions[purpose] = ConsentDecision(
          granted: (raw['granted'] as bool?) ?? false,
          at:      DateTime.tryParse((raw['atIso'] as String?) ?? ''),
        );
      }
    }
    return ConsentSettings(decisions: decisions);
  }

  final Map<ConsentPurpose, ConsentDecision> decisions;

  /// Sem decisão registrada, a permissão do sistema operacional (pedida no
  /// primeiro uso) vale como consentimento — o app não lê o GPS sem ela.
  bool isGranted(ConsentPurpose purpose) =>
      decisions[purpose]?.granted ?? true;

  ConsentSettings withDecision(ConsentPurpose purpose, {required bool granted}) =>
      ConsentSettings(
        decisions: {
          ...decisions,
          purpose: ConsentDecision(granted: granted, at: DateTime.now()),
        },
      );

  Map<String, dynamic> toMap() => {
        for (final e in decisions.entries)
          e.key.name: {
            'granted': e.value.granted,
            if (e.value.at != null) 'atIso': e.value.at!.toIso8601String(),
          },
      };
}

class ConsentDecision {
  const ConsentDecision({required this.granted, this.at});

  final bool granted;
  final DateTime? at;
}
