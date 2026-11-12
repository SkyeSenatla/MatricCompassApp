import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/app/retry_policy.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_repository.dart';
import 'package:matric_compass/features/students/domain/students_repository.dart';

void main() {
  test('"not found" is an answer, never retried', () {
    expect(appRetryPolicy(0, const BursaryNotFoundException('x')), isNull);
    expect(appRetryPolicy(0, const StudentNotFoundException('x')), isNull);
  });

  test('anything else is retried three times, backing off', () {
    final error = Exception('The network is down');
    expect(appRetryPolicy(0, error), const Duration(milliseconds: 200));
    expect(appRetryPolicy(1, error), const Duration(milliseconds: 400));
    expect(appRetryPolicy(2, error), const Duration(milliseconds: 800));
    expect(appRetryPolicy(3, error), isNull);
  });
}
