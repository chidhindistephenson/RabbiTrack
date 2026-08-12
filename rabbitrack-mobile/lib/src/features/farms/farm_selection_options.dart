import '../../shared/money_format.dart';
import '../auth/auth_models.dart';
import '../team/team_options.dart';

String farmSelectionSubtitle(FarmSummary farm) {
  return '${farm.code} | ${farmRoleLabel(farm.role)} | ${currencySymbol(farm.currency)}';
}

String farmSelectionHeader({
  required int farmCount,
  required bool hasSelectedFarm,
}) {
  if (farmCount == 0) {
    return 'Create your first farm to start using RabbiTrack.';
  }

  if (hasSelectedFarm) {
    return 'Choose a farm to switch your active rabbitry.';
  }

  if (farmCount == 1) {
    return 'Select your farm to continue.';
  }

  return 'Select the farm you want to work in.';
}
