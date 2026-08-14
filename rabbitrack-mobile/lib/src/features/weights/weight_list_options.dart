import 'weight_models.dart';

String weightListCountText(int count) {
  return count == 1 ? '1 record' : '$count records';
}

String latestWeightDate(List<WeightSummary> weights) {
  return weights.isEmpty ? '-' : weights.first.weighedOn;
}

String latestWeightValue(List<WeightSummary> weights) {
  if (weights.isEmpty) {
    return '-';
  }

  final latest = weights.first;
  return '${latest.weightValue} ${latest.weightUnit}';
}

String weightRecordTargetType(WeightSummary weight) {
  if (weight.rabbitIdentifier != null) {
    return 'Rabbit';
  }

  return 'Litter total';
}

String weightRecordValueText(WeightSummary weight) {
  if (weight.litterIdentifier != null && weight.averageWeightValue != null) {
    return '${weight.weightValue} ${weight.weightUnit} total | ${weight.averageWeightValue} ${weight.weightUnit}/kit';
  }

  return '${weight.weightValue} ${weight.weightUnit}';
}
