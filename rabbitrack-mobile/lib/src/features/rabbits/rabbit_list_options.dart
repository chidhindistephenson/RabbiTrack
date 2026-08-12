import 'rabbit_controller.dart';

bool hasActiveRabbitFilters(RabbitListFilters filters) {
  return filters.search != null ||
      filters.sex != null ||
      filters.status != null ||
      filters.breed != null;
}

String rabbitListSummaryText({
  required int count,
  required RabbitListFilters filters,
}) {
  final noun = count == 1 ? 'rabbit' : 'rabbits';

  return hasActiveRabbitFilters(filters)
      ? '$count matching $noun'
      : '$count total $noun';
}
