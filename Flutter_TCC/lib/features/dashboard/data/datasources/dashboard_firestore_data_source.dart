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

  // Atividades recentes requerem audit trail ainda não implementado no esquema.
  // Mock mantido intencionalmente — fora do escopo das ETAPAs atuais.
  Future<List<ActivityItem>> getRecentActivities() async {
    final now = DateTime.now();
    return [
      ActivityItem(
        type:     ActivityType.vaccination,
        title:    'Vacinação em lote — Aftosa',
        subtitle: '12 animais',
        date:     DateTime(now.year, now.month, now.day, 8, 14),
      ),
      ActivityItem(
        type:  ActivityType.birth,
        title: 'Parto — Mimosa #047',
        date:  DateTime(now.year, now.month, now.day - 1, 16, 32),
      ),
      ActivityItem(
        type:  ActivityType.brete,
        title: 'Brete · Ciclo abrir/fechar',
        date:  DateTime(now.year, now.month, now.day - 1, 14, 10),
      ),
    ];
  }
}
