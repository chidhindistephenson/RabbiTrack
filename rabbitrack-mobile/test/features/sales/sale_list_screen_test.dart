import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rabbitrack_mobile/src/features/sales/sale_controller.dart';
import 'package:rabbitrack_mobile/src/features/sales/sale_list_screen.dart';
import 'package:rabbitrack_mobile/src/features/sales/sale_models.dart';

void main() {
  testWidgets('SaleListScreen renders revenue and buyer details', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleListProvider.overrideWith((ref) async => _sales),
          saleReportProvider.overrideWith((ref) async => _report),
        ],
        child: const MaterialApp(home: SaleListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'$ 25.50'), findsWidgets);
    expect(find.text('SALE-001'), findsOneWidget);
    expect(find.text('Local buyer | 555-0100 | 2026-07-30'), findsOneWidget);
  });
}

const _sales = [
  SaleSummary(
    id: 'sale-1',
    rabbitId: 'rabbit-1',
    rabbitIdentifier: 'SALE-001',
    buyerName: 'Local buyer',
    buyerPhone: '555-0100',
    soldOn: '2026-07-30',
    salePrice: '25.50',
    currency: 'USD',
  ),
];

const _report = SaleReport(
  totalRevenue: '25.50',
  saleCount: 1,
  averageSale: '25.50',
  currency: 'USD',
);
