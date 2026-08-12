import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_status_options.dart';

void main() {
  test('rabbitStatusScreenTitle includes name when available', () {
    expect(
      rabbitStatusScreenTitle(identifier: 'DOE-0001', name: 'Luna'),
      'DOE-0001 - Luna',
    );
    expect(rabbitStatusScreenTitle(identifier: 'DOE-0001'), 'DOE-0001');
    expect(
      rabbitStatusScreenTitle(identifier: 'DOE-0001', name: '   '),
      'DOE-0001',
    );
  });

  test('rabbitStatusSexHint explains sex-specific status availability', () {
    expect(
      rabbitStatusSexHint('male'),
      'Pregnant and nursing are hidden because this rabbit is male.',
    );
    expect(
      rabbitStatusSexHint('female'),
      'Female reproductive statuses are available for this rabbit.',
    );
    expect(
      rabbitStatusSexHint('unknown'),
      'Set the rabbit sex in Edit profile to unlock sex-specific status rules.',
    );
  });

  test('rabbitCurrentStatusText labels current status', () {
    expect(
      rabbitCurrentStatusText('ready_for_sale'),
      'Current status: Ready for sale',
    );
  });
}
