import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/network/token_claims.dart';

import '../../support/fake_auth_server.dart';

void main() {
  test("reads the learner's email, role and student id", () {
    final claims = claimsOf(FakeAuthServer.accessToken(1));

    expect(claims?.email, 'thandiwe@matric-compass.test');
    expect(claims?.role, 'Learner');
    expect(claims?.studentId, 'student-1');
  });

  test('anything that is not a JWT gives null, not a crash', () {
    expect(claimsOf('not-a-token'), isNull);
    expect(claimsOf('a.%%%.c'), isNull);
    expect(claimsOf('a.bm90LWpzb24.c'), isNull);
  });
}
