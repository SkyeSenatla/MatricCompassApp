import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/careers/domain/aptitude_test.dart';
import 'package:matric_compass/features/careers/domain/tertiary_application.dart';
import 'package:matric_compass/features/careers/domain/tertiary_status.dart';

/// Week 10 Day 4: the Careers fakes' data.
///
/// From the API's seed: Thandiwe's Career Interest Inventory (score 82),
/// her University of Pretoria application and Sipho's UJ one. The API
/// recommends Computer Science, Accounting and Architecture for 70 to 84,
/// so those are copied here, not worked out. The API dates the test 14
/// days before startup; the fake fixes a date so tests don't depend on
/// today. The UCT and Stellenbosch applications are fake-only: one further
/// along the pipeline, and one with a status this app doesn't know.
abstract final class CareersSeed {
  /// Every aptitude test, newest first.
  static final List<AptitudeTest> aptitudeTests = [
    AptitudeTest(
      id: 'a7c1e000-0000-4000-8000-000000000001',
      studentId: Seed.thandiweId,
      testType: 'Career Interest Inventory',
      dateTaken: DateTime.utc(2026, 10, 28),
      score: 82,
      recommendedCareers: const [
        'Computer Science',
        'Accounting',
        'Architecture',
      ],
    ),
  ];

  /// Every university application.
  static const List<TertiaryApplication> tertiaryApplications = [
    TertiaryApplication(
      id: 'b8d2f000-0000-4000-8000-000000000001',
      studentId: Seed.thandiweId,
      institutionName: 'University of Pretoria',
      programmeName: 'BSc Computer Science',
      status: TertiaryStatus.researching,
    ),
    TertiaryApplication(
      id: 'b8d2f000-0000-4000-8000-000000000002',
      studentId: Seed.thandiweId,
      institutionName: 'University of Cape Town',
      programmeName: 'BSc Computer Engineering',
      status: TertiaryStatus.offered,
    ),
    TertiaryApplication(
      id: 'b8d2f000-0000-4000-8000-000000000003',
      studentId: Seed.thandiweId,
      institutionName: 'Stellenbosch University',
      programmeName: 'BAccLLB',
      // What a newer API might send one day.
      status: TertiaryStatus.unknown,
    ),
    TertiaryApplication(
      id: 'b8d2f000-0000-4000-8000-000000000004',
      studentId: Seed.siphoId,
      institutionName: 'University of Johannesburg',
      programmeName: 'BCom Accounting',
      status: TertiaryStatus.researching,
    ),
  ];
}
