import 'package:cloud_firestore/cloud_firestore.dart';

/// Anonimização dos chamados quando uma conta é excluída (LGPD).
///
/// Os chamados ficam como registro do atendimento para a outra parte, mas sem
/// dados que identifiquem quem excluiu a conta: a LGPD só permite guardar
/// dados pessoais depois do fim do tratamento quando eles são anonimizados
/// (Lei 13.709/2018, art. 16, IV, e art. 5.º, III e XI).
///
/// Os valores fixos abaixo são os mesmos exigidos por `firestore.rules`
/// (funções `isProducerAnonymization` e `isVetAnonymization`).
abstract final class ServiceCallAnonymization {
  static const String removedProducerId = 'removido';
  static const String removedProducerName = 'Usuário removido';
  static const String removedCity = 'Removido';
  static const String removedTitle = 'Pedido de usuário removido';
  static const String removedDescription =
      'Conteúdo removido na exclusão da conta.';
  static const String removedVetId = 'removido';
  static const String removedVetName = 'Veterinário removido';

  /// Campos opcionais que identificam o produtor e são apagados.
  static const List<String> producerOptionalFields = [
    'farmName',
    'lat',
    'lng',
    'animalEarTag',
  ];

  /// Alterações para um chamado do produtor que exclui a conta. Chamado ainda
  /// aberto é cancelado, para sair da lista dos veterinários.
  static Map<String, Object> producerUpdate(String? status) => {
        'producerId': removedProducerId,
        'producerName': removedProducerName,
        'city': removedCity,
        'title': removedTitle,
        'description': removedDescription,
        for (final f in producerOptionalFields) f: FieldValue.delete(),
        if (status == 'open') 'status': 'cancelled',
      };

  /// Alterações para um chamado do veterinário que exclui a conta: o id e o
  /// nome dele saem do chamado, e o laudo fica com o produtor. Atendimento
  /// ainda em andamento é cancelado, para o produtor poder pedir outro.
  static Map<String, Object> vetUpdate(String? status) => {
        'vetId': removedVetId,
        'vetName': removedVetName,
        if (status == 'accepted' || status == 'inProgress') 'status': 'cancelled',
      };
}
