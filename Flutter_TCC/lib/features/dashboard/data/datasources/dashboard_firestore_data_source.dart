import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/firestore_error_mapper.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/dashboard_stats.dart';

class DashboardFirestoreDataSource with FirestoreErrorHandler {
  DashboardFirestoreDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _animalsCol =>
      _firestore.collection('users/$_uid/animals');

  CollectionReference<Map<String, dynamic>> get _vaccinationsCol =>
      _firestore.collection('users/$_uid/vaccinations');

  CollectionReference<Map<String, dynamic>> get _weighingsCol =>
      _firestore.collection('users/$_uid/weighings');

  CollectionReference<Map<String, dynamic>> get _salesCol =>
      _firestore.collection('users/$_uid/sales');

  Future<DashboardStats> getStats() => guardFirestore(() async {
        final now = DateTime.now();
        final in30Days = now.add(const Duration(days: 30));

        // Conta apenas animais ATIVOS (exclui vendidos/óbito). Filtra em memória
        // sobre o campo normalizado — docs antigos sem `exitType` contam como
        // ativos, evitando o problema de `where` em campo ausente (ver §8.3).
        final animalsSnap = await _animalsCol.get();
        final active = animalsSnap.docs.where((d) {
          final exitType = (d.data()['exitType'] as String?) ?? 'active';
          return exitType == 'active';
        }).toList();

        final total    = active.length;
        final pregnant =
            active.where((d) => d.data()['status'] == 'pregnant').length;
        final alerts = active.where((d) {
          final status = d.data()['status'];
          return status == 'sick' || status == 'attention';
        }).length;

        // Próximas vacinações continua via aggregation (não baixa documentos).
        final upcomingSnap = await _vaccinationsCol
            .where('nextDoseDateIso',
                isGreaterThanOrEqualTo: now.toIso8601String())
            .where('nextDoseDateIso',
                isLessThanOrEqualTo: in30Days.toIso8601String())
            .count()
            .get();
        final upcoming = upcomingSnap.count ?? 0;

        return DashboardStats(
          totalAnimals:         total,
          pregnantCount:        pregnant,
          alertCount:           alerts,
          upcomingVaccinations: upcoming,
          alertMessage: alerts > 0
              ? '$alerts animal${alerts == 1 ? '' : 'is'} necessitam de atenção'
              : null,
        );
      });

  /// Atividades recentes REAIS do usuário: últimas vacinações, pesagens e
  /// vendas, mescladas e ordenadas da mais recente para a mais antiga.
  /// (Substitui o mock fixo que exibia eventos fictícios como se fossem dados.)
  Future<List<ActivityItem>> getRecentActivities({int limit = 6}) =>
      guardFirestore(() async {
        final results = await Future.wait([
          _vaccinationsCol
              .orderBy('dateIso', descending: true)
              .limit(limit)
              .get(),
          _weighingsCol.orderBy('dateIso', descending: true).limit(limit).get(),
          _salesCol.orderBy('dateIso', descending: true).limit(limit).get(),
          _animalsCol.get(),
        ]);

        final animalNames = {
          for (final d in results[3].docs) d.id: _animalLabel(d.data()),
        };
        String animalOf(Map<String, dynamic> data) =>
            animalNames[data['animalId']] ?? 'Animal removido';

        final items = <ActivityItem>[
          for (final d in results[0].docs)
            if (_date(d.data()) case final date?)
              ActivityItem(
                type:     ActivityType.vaccination,
                title:    'Vacinação — ${d.data()['vaccineName'] ?? 'vacina'}',
                subtitle: '${animalOf(d.data())} · ${d.data()['dose'] ?? ''}',
                date:     date,
              ),
          for (final d in results[1].docs)
            if (_date(d.data()) case final date?)
              ActivityItem(
                type:     ActivityType.weight,
                title:    'Pesagem — ${animalOf(d.data())}',
                subtitle: '${_kg(d.data()['weightKg'])} kg',
                date:     date,
              ),
          for (final d in results[2].docs)
            if (_date(d.data()) case final date?)
              ActivityItem(
                type:     ActivityType.other,
                title:    'Venda — ${_heads(d.data()['headCount'])}',
                subtitle: (d.data()['buyer'] as String?)?.trim().isNotEmpty ??
                        false
                    ? 'Comprador: ${d.data()['buyer']}'
                    : null,
                date:     date,
              ),
        ]..sort((a, b) => b.date.compareTo(a.date));

        return items.take(limit).toList();
      });

  // ---------------------------------------------------------------------------

  static DateTime? _date(Map<String, dynamic> data) =>
      DateTime.tryParse((data['dateIso'] as String?) ?? '');

  static String _animalLabel(Map<String, dynamic> data) {
    final name   = (data['name'] as String?)?.trim();
    final earTag = data['earTag'] ?? '?';
    return name != null && name.isNotEmpty ? '$name — #$earTag' : '#$earTag';
  }

  static String _kg(Object? value) =>
      value is num ? value.toStringAsFixed(0) : '?';

  static String _heads(Object? value) {
    final n = value is num ? value.toInt() : 0;
    return '$n ${n == 1 ? 'animal' : 'animais'}';
  }
}
