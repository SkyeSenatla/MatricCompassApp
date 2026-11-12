import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/careers/data/fake_careers_repository.dart';
import 'package:matric_compass/features/careers/domain/aptitude_test.dart';
import 'package:matric_compass/features/careers/domain/tertiary_status.dart';

void main() {
  FakeCareersRepository fakeFor(String ownerId) =>
      FakeCareersRepository(ownerId: ownerId, latency: Duration.zero);

  test("a learner gets her own applications, never anyone else's", () async {
    final applications = await fakeFor(Seed.thandiweId)
        .fetchTertiaryApplications();

    expect(applications.map((a) => a.institutionName), [
      'University of Pretoria',
      'University of Cape Town',
      'Stellenbosch University',
    ]);
    // Sipho's UJ application, as the API's owner scoping would hide it.
    expect(applications.where((a) => a.studentId != Seed.thandiweId), isEmpty);
  });

  test('her seeded test carries the careers the API recommends', () async {
    final tests = await fakeFor(Seed.thandiweId).fetchAptitudeTests();

    expect(tests.single.score, 82);
    expect(tests.single.recommendedCareers, [
      'Computer Science',
      'Accounting',
      'Architecture',
    ]);
  });

  test('aptitude tests come newest first', () async {
    AptitudeTest taken(String id, DateTime date) => AptitudeTest(
      id: id,
      studentId: 's',
      testType: 'Test $id',
      dateTaken: date,
      score: 60,
      recommendedCareers: const [],
    );
    final fake = FakeCareersRepository(
      ownerId: 's',
      latency: Duration.zero,
      aptitudeTests: [
        taken('old', DateTime.utc(2026)),
        taken('new', DateTime.utc(2026, 10)),
      ],
    );

    final tests = await fake.fetchAptitudeTests();

    expect(tests.map((t) => t.id), ['new', 'old']);
  });

  test('nobody signed in matches nobody', () async {
    final fake = fakeFor('');

    expect(await fake.fetchAptitudeTests(), isEmpty);
    expect(await fake.fetchTertiaryApplications(), isEmpty);
  });

  test(
    'a status the app does not know reaches the screen as unknown',
    () async {
      final applications = await fakeFor(Seed.thandiweId)
          .fetchTertiaryApplications();

      expect(
        applications.map((a) => a.status),
        contains(TertiaryStatus.unknown),
      );
    },
  );
}
