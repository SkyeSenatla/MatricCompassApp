import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_workflow.dart';

void main() {
  // The deadline is midnight UTC, as the app will send a picked date.
  final deadline = DateTime.utc(2027, 3, 31);

  BursaryApplication application(BursaryStatus status) => BursaryApplication(
    id: '0b6c1d0e-0000-4000-8000-000000000001',
    studentId: '0b6c1d0e-0000-4000-8000-0000000000aa',
    funder: 'NSFAS',
    amount: const Cents(4500000),
    deadline: deadline,
    status: status,
    requiredDocuments: const ['Certified ID Copy'],
    version: 1,
  );

  group('a draft', () {
    test('before the deadline can be edited, uploaded to and submitted', () {
      expect(
        learnerActions(
          application(BursaryStatus.draft),
          now: DateTime.utc(2027, 3),
        ),
        {
          LearnerAction.edit,
          LearnerAction.uploadDocuments,
          LearnerAction.submit,
        },
      );
    });

    test('can still be submitted late on the deadline day (UTC date)', () {
      expect(
        learnerActions(
          application(BursaryStatus.draft),
          now: DateTime.utc(2027, 3, 31, 23, 59),
        ),
        contains(LearnerAction.submit),
      );
    });

    test('after the deadline can no longer be submitted', () {
      expect(
        learnerActions(
          application(BursaryStatus.draft),
          now: DateTime.utc(2027, 4),
        ),
        {LearnerAction.edit, LearnerAction.uploadDocuments},
      );
    });
  });

  // One test per status: a new status needs a new line here, too.
  for (final status in [
    BursaryStatus.submitted,
    BursaryStatus.underReview,
    BursaryStatus.approved,
    BursaryStatus.rejected,
    BursaryStatus.unknown,
  ]) {
    test('a learner can do nothing to a ${status.name} application', () {
      expect(
        learnerActions(application(status), now: DateTime.utc(2027, 3)),
        isEmpty,
      );
    });
  }

  test('two applications with the same values are equal (freezed)', () {
    expect(application(BursaryStatus.draft), application(BursaryStatus.draft));
  });
}
