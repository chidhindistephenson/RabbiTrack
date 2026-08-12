import 'location_models.dart';

const locationTypes = ['house', 'section', 'row', 'cage', 'door'];

String locationTypeLabel(String type) {
  return switch (type) {
    'house' => 'House',
    'section' => 'Section',
    'row' => 'Row',
    'cage' => 'Cage',
    'door' => 'Door',
    _ => _sentenceCase(type),
  };
}

String locationOccupancyLabel(int occupiedCount, int? capacity) {
  if (capacity == null) {
    return '$occupiedCount occupied';
  }

  return '$occupiedCount / $capacity occupied';
}

double locationOccupancyRatio(int occupiedCount, int? capacity) {
  if (capacity == null || capacity <= 0) {
    return 0;
  }

  return (occupiedCount / capacity).clamp(0, 1);
}

String locationCountLabel(int count) {
  return count == 1 ? '1 location' : '$count locations';
}

String activeLocationCountLabel(List<FarmLocationSummary> locations) {
  final activeCount = locations.where((location) => location.isActive).length;

  return '$activeCount active';
}

String locationCapacitySummaryLabel(List<FarmLocationSummary> locations) {
  final totalCapacity = locations.fold<int>(
    0,
    (total, location) => total + (location.capacity ?? 0),
  );
  final occupied = locations.fold<int>(
    0,
    (total, location) => total + location.occupiedCount,
  );

  return totalCapacity == 0
      ? '$occupied occupied'
      : '$occupied / $totalCapacity occupied';
}

String locationCapacityStatusLabel(int occupiedCount, int? capacity) {
  if (capacity == null) {
    return '$occupiedCount assigned';
  }

  final remaining = capacity - occupiedCount;
  if (remaining <= 0) {
    return 'Full';
  }

  return remaining == 1 ? '1 space available' : '$remaining spaces available';
}

String locationTypeGuidance(String type) {
  return switch (type) {
    'house' => 'Use houses for major buildings or rabbitry blocks.',
    'section' => 'Use sections to group rows, cages, or work areas.',
    'row' => 'Use rows to organize cage lines inside a house or section.',
    'cage' => 'Use cages for individual rabbits or small groups.',
    'door' => 'Use doors for numbered cage openings or compartments.',
    _ => 'Create a clear farm space that rabbits can be assigned to.',
  };
}

String locationCapacityGuidance(String type) {
  return switch (type) {
    'cage' || 'door' => 'Set capacity to avoid overcrowding.',
    _ => 'Capacity is optional for broad areas.',
  };
}

String _sentenceCase(String value) {
  final words = value.split('_').where((part) => part.isNotEmpty).toList();

  if (words.isEmpty) {
    return value;
  }

  return [
    '${words.first[0].toUpperCase()}${words.first.substring(1)}',
    ...words.skip(1),
  ].join(' ');
}
