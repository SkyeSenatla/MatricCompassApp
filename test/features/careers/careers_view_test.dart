import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/fakes/careers_seed.dart';
import 'package:matric_compass/features/careers/presentation/careers_overview_provider.dart';
import 'package:matric_compass/features/careers/presentation/careers_view.dart';

void main() {
  const empty = CareersOverview(aptitudeTests: [], applications: []);

  test('loading', () {
    expect(
      CareersView.from(const AsyncLoading<CareersOverview>()),
      isA<CareersLoading>(),
    );
  });

  test('no tests and no applications is empty, not data', () {
    expect(CareersView.from(const AsyncData(empty)), isA<CareersEmpty>());
  });

  test('applications alone are data', () {
    expect(
      CareersView.from(
        const AsyncData(
          CareersOverview(
            aptitudeTests: [],
            applications: CareersSeed.tertiaryApplications,
          ),
        ),
      ),
      isA<CareersData>(),
    );
  });

  test('an error is a failure', () {
    expect(
      CareersView.from(
        AsyncError<CareersOverview>(Exception('down'), StackTrace.empty),
      ),
      isA<CareersFailure>(),
    );
  });
}
