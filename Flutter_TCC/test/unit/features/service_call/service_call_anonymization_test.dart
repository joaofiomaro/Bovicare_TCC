import 'package:bovicare/features/service_call/data/service_call_anonymization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceCallAnonymization.producerUpdate', () {
    test('troca os dados do produtor pelos valores fixos das regras', () {
      final u = ServiceCallAnonymization.producerUpdate('completed');
      expect(u['producerId'], 'removido');
      expect(u['producerName'], 'Usuário removido');
      expect(u['city'], 'Removido');
      expect(u['title'], 'Pedido de usuário removido');
      expect(u['description'], 'Conteúdo removido na exclusão da conta.');
    });

    test('apaga propriedade, localização e brinco', () {
      final u = ServiceCallAnonymization.producerUpdate('completed');
      for (final f in ['farmName', 'lat', 'lng', 'animalEarTag']) {
        expect(u[f], isA<FieldValue>(), reason: f);
      }
    });

    test('chamado aberto é cancelado; os demais mantêm o status', () {
      expect(ServiceCallAnonymization.producerUpdate('open')['status'], 'cancelled');
      for (final s in ['accepted', 'inProgress', 'completed', 'cancelled']) {
        expect(
          ServiceCallAnonymization.producerUpdate(s).containsKey('status'),
          isFalse,
          reason: s,
        );
      }
    });

    test('não mexe em campos do veterinário nem do atendimento', () {
      final u = ServiceCallAnonymization.producerUpdate('completed');
      for (final f in ['vetId', 'vetName', 'resolution', 'completedAtIso', 'state']) {
        expect(u.containsKey(f), isFalse, reason: f);
      }
    });
  });

  group('ServiceCallAnonymization.vetUpdate', () {
    test('tira o id e o nome do veterinário', () {
      expect(
        ServiceCallAnonymization.vetUpdate('completed'),
        {'vetId': 'removido', 'vetName': 'Veterinário removido'},
      );
    });

    test('atendimento em andamento é cancelado', () {
      for (final s in ['accepted', 'inProgress']) {
        expect(ServiceCallAnonymization.vetUpdate(s)['status'], 'cancelled', reason: s);
      }
    });
  });
}
