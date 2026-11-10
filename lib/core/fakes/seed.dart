import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

/// Week 10 Day 2: the fakes' data, shared so the dashboard and the detail
/// screen agree. Thandiwe and her NSFAS draft match the API's seed; the other
/// two are fake-only, to show a waiting status and one the app doesn't know.
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

  /// Her applications, in deadline order like the API's dashboard.
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
  ];
}
