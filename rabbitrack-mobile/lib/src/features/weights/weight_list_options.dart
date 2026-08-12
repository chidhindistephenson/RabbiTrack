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
