import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_controller.dart';
import 'package:rabbitrack_mobile/src/features/rabbits/rabbit_list_options.dart';

void main() {
  test('hasActiveRabbitFilters detects filter state', () {
    expect(hasActiveRabbitFilters(const RabbitListFilters()), isFalse);
    expect(
      hasActiveRabbitFilters(const RabbitListFilters(search: 'doe')),
      isTrue,
    );
    expect(
      hasActiveRabbitFilters(const RabbitListFilters(sex: 'female')),
      isTrue,
    );
    expect(
      hasActiveRabbitFilters(const RabbitListFilters(status: 'growing')),
      isTrue,
    );
    expect(
      hasActiveRabbitFilters(const RabbitListFilters(breed: 'Rex')),
      isTrue,
    );
  });

  test('rabbitListSummaryText describes filtered and unfiltered lists', () {
    expect(
      rabbitListSummaryText(count: 1, filters: const RabbitListFilters()),
      '1 total rabbit',
    );
    expect(
      rabbitListSummaryText(count: 4, filters: const RabbitListFilters()),
      '4 total rabbits',
    );
    expect(
      rabbitListSummaryText(
        count: 2,
        filters: const RabbitListFilters(status: 'ready_for_sale'),
      ),
      '2 matching rabbits',
    );
  });
}
