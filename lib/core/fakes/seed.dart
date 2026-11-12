import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

/// Week 10 Day 2: the fakes' data, shared so the dashboard and the detail
/// screen agree. Thandiwe and her NSFAS draft match the API's seed; the other
/// two are fake-only, to show a waiting status and one the app doesn't know.
///
/// Week 10 Day 3: Sipho and Ayanda are seeded students in the API too. Sipho's
/// application is fake-only: another learner's record, so a deep link to it
/// can prove "not yours" reads exactly like "doesn't exist".
abstract final class Seed {
  /// Thandiwe's student id.
  static const thandiweId = '7d0c3d1e-5a4b-4f1e-9a51-2a6c1e000114';

  /// Her NSFAS draft, as seeded in the API.
  static const nsfasId = '1f9e2c40-8b1a-4c7e-b2a3-5d6e7f800001';

  /// A submitted application (fake only).
  static const funzaId = '1f9e2c40-8b1a-4c7e-b2a3-5d6e7f800002';

  /// An application whose status this app doesn't know (fake only).
  static const withdrawnId = '1f9e2c40-8b1a-4c7e-b2a3-5d6e7f800003';

  /// Thandiwe's full name, as seeded in the API.
  static const thandiweName = 'Thandiwe Nkosi';

  /// Sipho's student id (fake only; his name is the API's seed).
  static const siphoId = '7d0c3d1e-5a4b-4f1e-9a51-2a6c1e000287';

  /// Ayanda's student id (fake only; her name is the API's seed).
  static const ayandaId = '7d0c3d1e-5a4b-4f1e-9a51-2a6c1e000342';

  /// Sipho's application: someone else's record, as Thandiwe sees it.
  static const siphoApplicationId = '1f9e2c40-8b1a-4c7e-b2a3-5d6e7f800004';

  /// Thandiwe's applications only: what her dashboard shows.
  static List<BursaryApplication> get thandiweApplications => [
    for (final application in applications)
      if (application.studentId == thandiweId) application,
  ];

  /// Every application, in deadline order like the API's dashboard.
  static final List<BursaryApplication> applications = [
    BursaryApplication(
      id: nsfasId,
      studentId: thandiweId,
      funder: 'NSFAS',
      amount: const Cents(4500000),
      deadline: DateTime.utc(2027, 3, 31),
      status: BursaryStatus.draft,
      requiredDocuments: const [
        'Certified ID Copy',
        'Proof of Household Income',
      ],
      version: 1,
    ),
    BursaryApplication(
      id: funzaId,
      studentId: thandiweId,
      funder: 'Funza Lushaka',
      amount: const Cents(8500000),
      deadline: DateTime.utc(2027, 4, 30),
      status: BursaryStatus.submitted,
      requiredDocuments: const ['Certified ID Copy'],
      version: 3,
      submittedAt: DateTime.utc(2026, 11, 2, 9, 30),
    ),
    BursaryApplication(
      id: withdrawnId,
      studentId: thandiweId,
      funder: 'Community Trust',
      amount: const Cents(1500000),
      deadline: DateTime.utc(2027, 5, 15),
      // What a newer API might send one day.
      status: BursaryStatus.fromApi('Withdrawn'),
      requiredDocuments: const [],
      version: 2,
    ),
    BursaryApplication(
      id: siphoApplicationId,
      studentId: siphoId,
      funder: 'Sasol Foundation',
      amount: const Cents(6000000),
      deadline: DateTime.utc(2027, 6, 30),
      status: BursaryStatus.underReview,
      requiredDocuments: const ['Certified ID Copy'],
      version: 2,
      submittedAt: DateTime.utc(2026, 10, 20, 8),
    ),
  ];
}
