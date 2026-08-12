import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/breeding/breeding_options.dart';

void main() {
  test('breeding labels format statuses and results', () {
    expect(
      breedingStatusLabel('awaiting_pregnancy_check'),
      'Awaiting pregnancy check',
    );
    expect(breedingStatusLabel('pregnant'), 'Pregnant');
    expect(pregnancyCheckResultLabel('not_pregnant'), 'Not pregnant');
    expect(matingOutcomeLabel('observed'), 'Observed');
    expect(matingOutcomeLabel(null), '-');
  });

  test('canRecordPregnancyCheck allows only open check states', () {
    expect(canRecordPregnancyCheck('awaiting_pregnancy_check'), isTrue);
    expect(canRecordPregnancyCheck('uncertain'), isTrue);
    expect(canRecordPregnancyCheck('pregnant'), isFalse);
    expect(canRecordPregnancyCheck('not_pregnant'), isFalse);
    expect(canRecordPregnancyCheck('kindled'), isFalse);
  });

  test('isPregnancyCheckDue requires open status and due date to pass', () {
    final today = DateTime(2026, 8, 4);

    expect(
      isPregnancyCheckDue(
        status: 'awaiting_pregnancy_check',
        dueOn: '2026-08-04',
        today: today,
      ),
      isTrue,
    );
    expect(
      isPregnancyCheckDue(
        status: 'awaiting_pregnancy_check',
        dueOn: '2026-08-05',
        today: today,
      ),
      isFalse,
    );
    expect(
      isPregnancyCheckDue(
        status: 'pregnant',
        dueOn: '2026-08-04',
        today: today,
      ),
      isFalse,
    );
  });

  test('mating selection requires available breeding status', () {
    expect(canSelectDoeForMating('available_for_breeding'), isTrue);
    expect(canSelectDoeForMating('awaiting_pregnancy_check'), isFalse);
    expect(canSelectDoeForMating('pregnant'), isFalse);

    expect(canSelectBuckForMating('available_for_breeding'), isTrue);
    expect(canSelectBuckForMating('sold'), isFalse);
  });

  test('pregnancy decision can be revised only after a decision exists', () {
    expect(canRevisePregnancyDecision('pregnant'), isTrue);
    expect(canRevisePregnancyDecision('not_pregnant'), isTrue);
    expect(canRevisePregnancyDecision('uncertain'), isTrue);
    expect(canRevisePregnancyDecision('awaiting_pregnancy_check'), isFalse);
  });

  test('kindling can only be recorded after confirmed pregnancy', () {
    expect(canRecordKindling('pregnant'), isTrue);
    expect(canRecordKindling('awaiting_pregnancy_check'), isFalse);
    expect(canRecordKindling('uncertain'), isFalse);
    expect(canRecordKindling('kindled'), isFalse);
  });
}
