import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_item.freezed.dart';

enum ActivityType { vaccination, birth, brete, weight, newAnimal, other }

@freezed
class ActivityItem with _$ActivityItem {
  const factory ActivityItem({
    required ActivityType type,
    required String title,
    required DateTime date,
    String? subtitle,
  }) = _ActivityItem;
}
