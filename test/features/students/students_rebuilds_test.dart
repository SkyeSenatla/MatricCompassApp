import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/app.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/data_source.dart';
import 'package:matric_compass/app/retry_policy.dart';
import 'package:matric_compass/app/settings/theme_setting.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/core/fakes/fake_latency_provider.dart';
import 'package:matric_compass/features/auth/data/fake_personas.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:matric_compass/features/students/data/students_repository_provider.dart';
import 'package:matric_compass/features/students/domain/student.dart';
import 'package:matric_compass/features/students/domain/students_repository.dart';

import '../../support/test_database.dart';

/// 300 students, as the class's API has after add_perf_students.ps1.
final class _ManyStudents implements StudentsRepository {
  static final List<Student> students = [
    for (var i = 1; i <= 300; i++)
      Student(
        id: 'perf-$i',
        fullName: 'Perf Learner ${i.toString().padLeft(3, '0')}',
        learnerNumber: 'PERF-${i.toString().padLeft(4, '0')}',
      ),
  ];

  @override
  Future<Result<List<Student>>> fetchAll() async => Ok(students);

  @override
  Future<Result<StudentProfile>> fetchById(String id) async => Ok(
    StudentProfile(
      student: students.firstWhere((s) => s.id == id),
      applications: const [],
    ),
  );
}

const _config = AppConfig(flavor: Flavor.prod, apiBaseUrl: 'https://x');

/// Week 12 Day 2: the DevTools finding, kept as a test. On a tablet the
/// students list sits beside the selected student. Choosing another
/// student must not rebuild every row, and must not lose the list's place.
void main() {
  testWidgets('choosing a student on a tablet rebuilds two rows, and the '
      'list keeps its place', (tester) async {
    tester.view
      ..physicalSize = const Size(1000, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.defaultRouteNameTestValue =
        '/staff/students/perf-1';
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    final container = ProviderContainer.test(
      overrides: [
        dataSourceProvider.overrideWithValue(DataSource.fake),
        fakeLatencyProvider.overrideWithValue(Duration.zero),
        appConfigProvider.overrideWithValue(_config),
        inMemoryDatabase,
        settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
        studentsRepositoryProvider.overrideWithValue(_ManyStudents()),
      ],
      retry: appRetryPolicy,
    );
    await container
        .read(authControllerProvider.notifier)
        .signIn(FakePersonas.counsellor.email, 'any password');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MatricCompassApp(config: _config),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll the list well down, and choose a student there.
    final list = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Perf Learner 150'),
      300,
      scrollable: list,
    );
    await tester.pumpAndSettle();
    final before = tester.state<ScrollableState>(list).position.pixels;
    expect(before, greaterThan(0));

    // The same count DevTools' rebuild stats show: rebuilds per widget.
    final rebuilds = <String, int>{};
    debugOnRebuildDirtyWidget = (element, builtOnce) {
      final type = element.widget.runtimeType.toString();
      rebuilds[type] = (rebuilds[type] ?? 0) + 1;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    await tester.tap(find.text('Perf Learner 150'));
    await tester.pumpAndSettle();
    debugOnRebuildDirtyWidget = null;

    // Before Day 2: every row on screen, 17 of them. Now only the rows
    // whose answer to "am I selected?" changed: at most two (one here: the
    // old selection is scrolled out of view).
    expect(rebuilds['ListTile'], lessThanOrEqualTo(2));
    expect(
      tester.state<ScrollableState>(list).position.pixels,
      before,
      reason: 'the list keeps its place',
    );
  });
}
