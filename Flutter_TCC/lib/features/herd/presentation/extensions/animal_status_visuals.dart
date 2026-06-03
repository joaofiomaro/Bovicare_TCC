import '../../../../shared/widgets/app_badge.dart';
import '../../domain/entities/animal_entity.dart';

/// Mapeamento visual de [AnimalStatus] → [BadgeType] na camada de apresentação.
/// Fonte única de verdade — usada por `AnimalListTile` e `AnimalProfileScreen`.
extension AnimalStatusVisuals on AnimalStatus {
  BadgeType get badge => switch (this) {
        AnimalStatus.healthy   => BadgeType.info,
        AnimalStatus.pregnant  => BadgeType.success,
        AnimalStatus.attention => BadgeType.warning,
        AnimalStatus.sick      => BadgeType.danger,
      };
}
