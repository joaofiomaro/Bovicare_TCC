import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../herd/presentation/providers/animals_provider.dart';
import '../../../vaccination/presentation/providers/vaccinations_provider.dart';
import '../../domain/entities/report_data.dart';
import '../../domain/usecases/generate_report_use_case.dart';

/// Filtro atual selecionado na tela de relatórios.
final reportFilterProvider = StateProvider<ReportFilter>(
  (_) => const ReportFilter(),
);

/// Estado da geração do relatório (null = nenhum gerado ainda).
class ReportNotifier extends AsyncNotifier<ReportData?> {
  @override
  Future<ReportData?> build() async => null;

  Future<void> generate(ReportType type) async {
    state = const AsyncLoading();
    final filter = ref.read(reportFilterProvider);
    state = await AsyncValue.guard(() async {
      final useCase = GenerateReportUseCase(
        animals:      ref.read(animalRepositoryProvider),
        vaccinations: ref.read(vaccinationRepositoryProvider),
      );
      return useCase.call(type, filter);
    });
  }

  void clear() => state = const AsyncData(null);
}

final reportProvider =
    AsyncNotifierProvider<ReportNotifier, ReportData?>(ReportNotifier.new);
