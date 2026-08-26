import '../features/auth/auth_models.dart';
import '../features/home/farm_summary_models.dart';
import '../features/breeding/mating_models.dart';
import '../features/expenses/expense_models.dart';
import '../features/health/health_models.dart';
import '../features/locations/location_models.dart';
import '../features/litters/litter_models.dart';
import '../features/rabbits/rabbit_models.dart';
import '../features/reports/finance_report_models.dart';
import '../features/reports/breeding_calendar_models.dart';
import '../features/reports/health_report_models.dart';
import '../features/reports/population_report_models.dart';
import '../features/sales/sale_models.dart';
import '../features/tasks/task_models.dart';

bool isOfflineDemoSession(AuthSession? session) {
  return session?.token.startsWith('offline-demo-') == true ||
      session?.selectedFarm?.id == 'offline-demo-farm';
}

bool isOfflineDemoFarm(String farmId) => farmId == 'offline-demo-farm';

bool isOfflineEmptyFarm(String farmId) => farmId == 'offline-empty-farm';

bool isOfflineFarm(String farmId) {
  return isOfflineDemoFarm(farmId) || isOfflineEmptyFarm(farmId);
}

const offlineDemoFarmSummary = FarmSummaryCounts(
  activeRabbits: 7,
  does: 5,
  bucks: 2,
  liveKits: 9,
  readyForSale: 0,
  healthAlerts: 2,
  quarantined: 0,
  pregnantDoes: 1,
  nursingDoes: 1,
  openTasks: 4,
  overdueTasks: 0,
  expectedKindlings: 1,
  totalSales: 2,
  salesRevenue: '43.75',
  totalExpenses: '25.00',
  netIncome: '18.75',
  currency: 'USD',
);

const offlineEmptyFarmSummary = FarmSummaryCounts(
  activeRabbits: 0,
  does: 0,
  bucks: 0,
  liveKits: 0,
  readyForSale: 0,
  healthAlerts: 0,
  quarantined: 0,
  pregnantDoes: 0,
  nursingDoes: 0,
  openTasks: 0,
  overdueTasks: 0,
  expectedKindlings: 0,
  totalSales: 0,
  salesRevenue: '0.00',
  totalExpenses: '0.00',
  netIncome: '0.00',
  currency: 'USD',
);

const offlineDemoTaskSummary = TaskSummaryCounts(today: 1, overdue: 0, open: 4);

List<TaskSummary> offlineDemoTasks(DateTime now) {
  final today = _dateValue(now);
  final tomorrow = _dateValue(now.add(const Duration(days: 1)));
  final nextWeek = _dateValue(now.add(const Duration(days: 7)));

  return [
    TaskSummary(
      id: 'offline-task-pregnancy-check',
      type: 'pregnancy_check',
      title: 'Pregnancy check for DOE-0047',
      description: 'Confirm status after the mating window.',
      dueOn: today,
      dueTime: '08:00',
      priority: 'high',
      status: 'open',
      rabbitIdentifier: 'DOE-0047',
    ),
    TaskSummary(
      id: 'offline-task-health-review',
      type: 'health',
      title: 'Review 2 health alerts',
      description: 'Check rabbits currently marked for attention.',
      dueOn: tomorrow,
      dueTime: '09:00',
      priority: 'normal',
      status: 'open',
    ),
    TaskSummary(
      id: 'offline-task-identify-kits',
      type: 'identify_kits',
      title: 'Identify/tag kits from LIT-DEMO',
      description: 'Prepare kit IDs after weaning.',
      dueOn: nextWeek,
      dueTime: '10:00',
      priority: 'normal',
      status: 'open',
      rabbitIdentifier: 'DOE-0047',
    ),
  ];
}

MonthlyFinanceReport offlineDemoFinanceReport(DateTime now) {
  final rows = <MonthlyFinanceRow>[];

  for (var offset = 5; offset >= 0; offset--) {
    final date = DateTime(now.year, now.month - offset);
    final isCurrentMonth = offset == 0;

    rows.add(
      MonthlyFinanceRow(
        month:
            '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}',
        label: '${_monthLabel(date.month)} ${date.year}',
        revenue: isCurrentMonth ? '43.75' : '0.00',
        expenses: isCurrentMonth ? '25.00' : '0.00',
        netIncome: isCurrentMonth ? '18.75' : '0.00',
      ),
    );
  }

  return MonthlyFinanceReport(currency: 'USD', months: rows);
}

List<RabbitSummary> offlineDemoRabbits({
  String? search,
  String? sex,
  String? status,
  String? breed,
}) {
  final normalizedSearch = search?.trim().toLowerCase();

  return _offlineDemoRabbitDetails.where((rabbit) {
    final matchesSearch =
        normalizedSearch == null ||
        normalizedSearch.isEmpty ||
        [
          rabbit.identifier,
          rabbit.name,
          rabbit.breed,
          rabbit.currentLocationName,
        ].whereType<String>().any(
          (value) => value.toLowerCase().contains(normalizedSearch),
        );
    final matchesSex = sex == null || sex.isEmpty || rabbit.sex == sex;
    final matchesStatus =
        status == null || status.isEmpty || rabbit.status == status;
    final matchesBreed =
        breed == null || breed.isEmpty || rabbit.breed == breed;

    return matchesSearch && matchesSex && matchesStatus && matchesBreed;
  }).toList();
}

RabbitDetail? offlineDemoRabbitDetail(String rabbitId) {
  for (final rabbit in _offlineDemoRabbitDetails) {
    if (rabbit.id == rabbitId || rabbit.identifier == rabbitId) {
      return rabbit;
    }
  }

  return null;
}

List<FarmLocationSummary> offlineDemoLocations() {
  return _offlineDemoLocations;
}

FarmLocationDetail? offlineDemoLocationDetail(String locationId) {
  for (final location in _offlineDemoLocationDetails) {
    if (location.id == locationId) {
      return location;
    }
  }

  return null;
}

List<MatingSummary> offlineDemoMatings({String? rabbitId}) {
  return _offlineDemoMatingDetails
      .where((mating) => rabbitId == null || mating.doeId == rabbitId)
      .toList();
}

MatingDetail? offlineDemoMatingDetail(String matingId) {
  for (final mating in _offlineDemoMatingDetails) {
    if (mating.id == matingId) {
      return mating;
    }
  }

  return null;
}

List<LitterSummary> offlineDemoLitters() {
  return _offlineDemoLitterDetails;
}

LitterDetail? offlineDemoLitterDetail(String litterId) {
  for (final litter in _offlineDemoLitterDetails) {
    if (litter.id == litterId) {
      return litter;
    }
  }

  return null;
}

List<HealthEventSummary> offlineDemoHealthEvents({String? rabbitId}) {
  return _offlineDemoHealthEvents
      .where(
        (event) =>
            rabbitId == null ||
            event.rabbitIdentifier ==
                offlineDemoRabbitDetail(rabbitId)?.identifier,
      )
      .toList();
}

List<SaleSummary> offlineDemoSales({String? rabbitId}) {
  return _offlineDemoSales
      .where((sale) => rabbitId == null || sale.rabbitId == rabbitId)
      .toList();
}

const offlineDemoSaleReport = SaleReport(
  totalRevenue: '43.75',
  saleCount: 1,
  averageSale: '43.75',
  currency: 'USD',
);

List<ExpenseSummary> offlineDemoExpenses() {
  return _offlineDemoExpenses;
}

const offlineDemoExpenseReport = ExpenseReport(
  total: '25.00',
  currency: 'USD',
  byCategory: [
    ExpenseCategoryTotal(category: 'feed', total: '25.00', count: 1),
  ],
);

const offlineDemoHealthReport = HealthReport(
  activeHealthEvents: 1,
  activeTreatments: 1,
  withdrawalRestrictions: 0,
  mortalityCount: 0,
  eventsBySeverity: [HealthReportRow(label: 'mild', count: 1)],
  eventsByBodySystem: [HealthReportRow(label: 'respiratory', count: 1)],
  eventsByDiagnosis: [
    HealthReportRow(label: 'Monitor respiratory signs', count: 1),
  ],
  medicineUse: [HealthReportRow(label: 'Observation', count: 1)],
  withdrawals: [],
);

const offlineDemoPopulationReport = PopulationReport(
  total: 4,
  bySex: [
    PopulationReportRow(label: 'female', count: 2),
    PopulationReportRow(label: 'male', count: 1),
    PopulationReportRow(label: 'unknown', count: 1),
  ],
  byStatus: [
    PopulationReportRow(label: 'available_for_breeding', count: 2),
    PopulationReportRow(label: 'pregnant', count: 1),
    PopulationReportRow(label: 'growing', count: 1),
  ],
  byBreed: [
    PopulationReportRow(label: 'New Zealand White', count: 2),
    PopulationReportRow(label: 'Rex', count: 1),
    PopulationReportRow(label: 'Californian', count: 1),
  ],
  byLocation: [
    PopulationReportRow(label: 'House 1', count: 3),
    PopulationReportRow(label: 'Nursery', count: 1),
  ],
);

List<BreedingCalendarEvent> offlineDemoBreedingCalendar() {
  return const [
    BreedingCalendarEvent(
      date: '2026-08-29',
      type: 'pregnancy_check',
      title: 'Pregnancy check: DOE-0047',
      subtitle: 'Mated with BUCK-0003',
      relatedType: 'mating',
      relatedId: 'offline-mating-001',
      rabbitId: 'offline-doe-0047',
      rabbitIdentifier: 'DOE-0047',
    ),
    BreedingCalendarEvent(
      date: '2026-09-12',
      type: 'nest_box',
      title: 'Nest box: DOE-0047',
      subtitle: 'Expected kindling 2026-09-15',
      relatedType: 'mating',
      relatedId: 'offline-mating-001',
      rabbitId: 'offline-doe-0047',
      rabbitIdentifier: 'DOE-0047',
    ),
    BreedingCalendarEvent(
      date: '2026-09-17',
      type: 'weaning',
      title: 'Planned weaning: LIT-DEMO',
      subtitle: '9 live kits',
      relatedType: 'litter',
      relatedId: 'offline-litter-001',
      rabbitId: 'offline-doe-0047',
      rabbitIdentifier: 'DOE-0047',
    ),
  ];
}

const _offlineDemoMatingDetails = [
  MatingDetail(
    id: 'offline-mating-001',
    doeId: 'offline-doe-0047',
    doeIdentifier: 'DOE-0047',
    buckIdentifier: 'BUCK-0003',
    pregnancyCheckDueOn: '2026-08-29',
    expectedKindlingOn: '2026-09-15',
    status: 'awaiting_pregnancy_check',
    matedAt: '2026-08-15',
    outcome: 'observed',
    behaviorObserved: 'Normal mating observed',
    nestBoxDueOn: '2026-09-12',
    notes: 'Starter demo mating record.',
    pregnancyChecks: [],
    litters: [],
  ),
];

const _offlineDemoLitterDetails = [
  LitterDetail(
    id: 'offline-litter-001',
    identifier: 'LIT-DEMO',
    doeId: 'offline-doe-0047',
    doeIdentifier: 'DOE-0047',
    buckId: 'offline-buck-0003',
    buckIdentifier: 'BUCK-0003',
    kindledOn: '2026-08-13',
    currentLiveCount: 9,
    plannedWeaningOn: '2026-09-17',
    status: 'nursing',
    kitsBornAlive: 9,
    kitsStillborn: 1,
    kitsWeak: 0,
    convertedRabbitsCount: 0,
    unconvertedKitsCount: 9,
    notes: 'Starter litter record for testing weaning and kit identification.',
    checks: [
      LitterCheckSummary(
        id: 'offline-litter-check-001',
        checkedOn: '2026-08-14',
        liveCount: 9,
        deadCount: 0,
        weakCount: 0,
        nestObservation: 'Warm nest, kits grouped together',
        correctiveAction: 'Continue daily checks',
      ),
    ],
    fostersOut: [],
    fostersIn: [],
    weanings: [],
    weights: [
      LitterWeightSummary(
        id: 'offline-litter-weight-001',
        weighedOn: '2026-08-13',
        weightValue: '0.72',
        weightUnit: 'kg',
        stage: 'birth',
        kitCount: 9,
        averageWeightValue: '0.08',
        method: 'litter_total',
      ),
    ],
  ),
];

const _offlineDemoHealthEvents = [
  HealthEventSummary(
    id: 'offline-health-001',
    rabbitIdentifier: 'DOE-0047',
    observedOn: '2026-08-18',
    symptoms: 'Mild sneezing observed during feeding',
    diagnosis: 'Monitor respiratory signs',
    bodySystem: 'respiratory',
    severity: 'mild',
    status: 'monitoring',
    isolationRequired: false,
    treatmentsCount: 1,
    notes: 'Demo health record.',
  ),
];

const _offlineDemoSales = [
  SaleSummary(
    id: 'offline-sale-001',
    rabbitId: 'offline-grower-001',
    rabbitIdentifier: 'KIT-0001',
    buyerName: 'Local buyer',
    buyerPhone: '+263 000 000',
    soldOn: '2026-08-18',
    salePrice: '43.75',
    currency: 'USD',
    notes: 'Demo sale record.',
  ),
];

const _offlineDemoExpenses = [
  ExpenseSummary(
    id: 'offline-expense-001',
    category: 'feed',
    vendor: 'Local feed store',
    spentOn: '2026-08-18',
    amount: '25.00',
    currency: 'USD',
    notes: 'Demo feed purchase.',
  ),
];

const _offlineDemoLocations = [
  FarmLocationSummary(
    id: 'offline-house-1',
    type: 'house',
    name: 'House 1',
    code: 'H1',
    capacity: 40,
    occupiedCount: 3,
    isActive: true,
  ),
  FarmLocationSummary(
    id: 'offline-nursery',
    type: 'cage',
    name: 'Nursery',
    code: 'NUR',
    capacity: 20,
    occupiedCount: 1,
    isActive: true,
  ),
  FarmLocationSummary(
    id: 'offline-quarantine',
    type: 'cage',
    name: 'Quarantine',
    code: 'Q1',
    capacity: 6,
    occupiedCount: 0,
    isActive: true,
  ),
];

const _offlineDemoLocationDetails = [
  FarmLocationDetail(
    id: 'offline-house-1',
    type: 'house',
    name: 'House 1',
    code: 'H1',
    capacity: 40,
    occupiedCount: 3,
    isActive: true,
    rabbits: [
      LocationRabbitSummary(
        id: 'offline-doe-0047',
        identifier: 'DOE-0047',
        name: 'Mjolnir',
        sex: 'female',
        status: 'pregnant',
        breed: 'New Zealand White',
      ),
      LocationRabbitSummary(
        id: 'offline-buck-0003',
        identifier: 'BUCK-0003',
        name: 'Atlas',
        sex: 'male',
        status: 'available_for_breeding',
        breed: 'New Zealand White',
      ),
      LocationRabbitSummary(
        id: 'offline-doe-rex',
        identifier: 'DOE-0048',
        name: 'Freya',
        sex: 'female',
        status: 'available_for_breeding',
        breed: 'Rex',
      ),
    ],
  ),
  FarmLocationDetail(
    id: 'offline-nursery',
    type: 'cage',
    name: 'Nursery',
    code: 'NUR',
    capacity: 20,
    occupiedCount: 1,
    isActive: true,
    rabbits: [
      LocationRabbitSummary(
        id: 'offline-grower-001',
        identifier: 'KIT-0001',
        name: 'Sprout',
        sex: 'unknown',
        status: 'growing',
        breed: 'Californian',
      ),
    ],
  ),
  FarmLocationDetail(
    id: 'offline-quarantine',
    type: 'cage',
    name: 'Quarantine',
    code: 'Q1',
    capacity: 6,
    occupiedCount: 0,
    isActive: true,
    rabbits: [],
  ),
];

const _offlineDemoRabbitDetails = [
  RabbitDetail(
    id: 'offline-doe-0047',
    identifier: 'DOE-0047',
    name: 'Mjolnir',
    sex: 'female',
    dateOfBirth: '2025-02-14',
    breed: 'New Zealand White',
    colour: 'White',
    weightValue: '4.30',
    weightUnit: 'kg',
    status: 'pregnant',
    currentLocationName: 'House 1',
    movements: [],
    notes: 'Offline demo doe for testing breeding and dashboard flows.',
  ),
  RabbitDetail(
    id: 'offline-buck-0003',
    identifier: 'BUCK-0003',
    name: 'Atlas',
    sex: 'male',
    dateOfBirth: '2025-01-10',
    breed: 'New Zealand White',
    colour: 'White',
    weightValue: '4.80',
    weightUnit: 'kg',
    status: 'available_for_breeding',
    currentLocationName: 'House 1',
    movements: [],
    notes: 'Offline demo buck for testing profile and mating screens.',
  ),
  RabbitDetail(
    id: 'offline-doe-rex',
    identifier: 'DOE-0048',
    name: 'Freya',
    sex: 'female',
    dateOfBirth: '2025-05-02',
    breed: 'Rex',
    colour: 'Black',
    weightValue: '3.60',
    weightUnit: 'kg',
    status: 'available_for_breeding',
    currentLocationName: 'House 1',
    movements: [],
  ),
  RabbitDetail(
    id: 'offline-grower-001',
    identifier: 'KIT-0001',
    name: 'Sprout',
    sex: 'unknown',
    dateOfBirth: '2026-08-13',
    breed: 'Californian',
    colour: 'White',
    weightValue: '0.42',
    weightUnit: 'kg',
    status: 'growing',
    currentLocationName: 'Nursery',
    movements: [],
  ),
];

String _dateValue(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _monthLabel(int month) {
  const labels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return labels[month - 1];
}
