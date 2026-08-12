import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_options.dart';

void main() {
  test('southernAfricaRabbitBreeds includes the supported breed list', () {
    expect(
      southernAfricaRabbitBreeds,
      containsAllInOrder([
        'Phendula',
        'New Zealand White',
        'Californian',
        'Chinchilla Rabbit',
        'Flemish Giant',
        'German Lop',
        'Netherland Dwarf',
        'Rex',
        'Dutch Rabbit',
        'Riverine Rabbit',
        "Hewitt's Red Rock Rabbit",
      ]),
    );
  });

  test('rabbitStatusLabel formats important statuses', () {
    expect(rabbitStatusLabel('ready_for_sale'), 'Ready for sale');
    expect(
      rabbitStatusLabel('awaiting_pregnancy_check'),
      'Awaiting pregnancy check',
    );
  });

  test('rabbitStatusesForSex removes pregnancy statuses for males', () {
    expect(rabbitStatusesForSex('female'), contains('pregnant'));
    expect(rabbitStatusesForSex('female'), contains('nursing'));
    expect(rabbitStatusesForSex('male'), isNot(contains('pregnant')));
    expect(rabbitStatusesForSex('male'), isNot(contains('nursing')));
  });

  test(
    'editableRabbitStatusesForSex removes sold from manual status choices',
    () {
      expect(editableRabbitStatusesForSex('female'), isNot(contains('sold')));
      expect(editableRabbitStatusesForSex('male'), isNot(contains('sold')));
      expect(
        editableRabbitStatusesForSex('female'),
        contains('ready_for_sale'),
      );
    },
  );

  test('rabbit sex helpers show explicit labels and initials', () {
    expect(rabbitSexLabel('female'), 'Female');
    expect(rabbitSexLabel('male'), 'Male');
    expect(rabbitSexLabel('unknown'), 'Unknown');
    expect(rabbitSexInitial('female'), 'D');
    expect(rabbitSexInitial('male'), 'B');
    expect(rabbitSexInitial('unknown'), '?');
  });
}
