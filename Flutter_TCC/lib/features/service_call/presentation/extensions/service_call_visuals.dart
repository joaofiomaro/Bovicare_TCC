import '../../../../shared/widgets/app_badge.dart';
import '../../domain/entities/service_call.dart';

/// Mapeamento visual de [ServiceStatus] → [BadgeType] na camada de apresentação.
/// Fonte única de verdade para tiles, dashboard e ficha do chamado.
extension ServiceStatusVisuals on ServiceStatus {
  BadgeType get badge => switch (this) {
        ServiceStatus.open        => BadgeType.info,
        ServiceStatus.accepted    => BadgeType.success,
        ServiceStatus.inProgress  => BadgeType.warning,
        ServiceStatus.completed   => BadgeType.neutral,
        ServiceStatus.cancelled   => BadgeType.danger,
      };
}

extension ServiceUrgencyVisuals on ServiceUrgency {
  BadgeType get badge => switch (this) {
        ServiceUrgency.low    => BadgeType.neutral,
        ServiceUrgency.normal => BadgeType.info,
        ServiceUrgency.high   => BadgeType.danger,
      };
}
