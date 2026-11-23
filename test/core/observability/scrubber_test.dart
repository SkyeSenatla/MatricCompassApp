import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/observability/scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Week 12 Day 2: the scrubber, fed the kind of event a real failure makes,
/// with personal information in every place it could hide.
void main() {
  const thandiwe = (
    name: 'Thandiwe Nkosi',
    email: 'thandiwe@matric-compass.test',
  );
  const jwt =
      'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.c2lnbmF0dXJlLXNpZ25hdHVyZQ';

  SentryEvent realistic() => SentryEvent(
    message: SentryMessage(
      'Bursary for Thandiwe Nkosi (thandiwe@matric-compass.test) failed '
      'at R 45 000,00',
    ),
    exceptions: [
      SentryException(
        type: 'StateError',
        value:
            'Bad state: no application for THANDIWE NKOSI, '
            'ID 0801015800083, phone 082 555 1234, Authorization: Bearer $jwt',
      ),
    ],
    breadcrumbs: [
      Breadcrumb(
        message: 'GET /api/v1/bursary-applications?studentId=7d0c&q=Nkosi',
        category: 'http',
        data: {
          'url': 'http://10.0.2.2:5146/api/v1/students?email=sipho@x.test',
          'method': 'GET',
          'status_code': 500,
          'body': '{"fullName":"Sipho Dlamini"}',
        },
      ),
    ],
    user: SentryUser(
      id: 'user-42',
      email: 'thandiwe@matric-compass.test',
      name: 'Thandiwe Nkosi',
      ipAddress: '196.25.1.1',
    ),
    request: SentryRequest(
      url: 'http://10.0.2.2:5146/api/v1/auth/refresh',
      cookies: 'refresh_token=abc123',
      headers: {'Authorization': 'Bearer $jwt'},
    ),
    tags: {
      'correlation_id': '00-4bf92f3577b34da6a3ce929d0e0e4736-01',
      'note': 'R 450,00 for thandiwe@matric-compass.test',
    },
  );

  test('nothing personal survives the scrubber', () {
    final event = Scrubber(() => thandiwe).call(realistic(), Hint())!;
    final sent = jsonEncode(event.toJson());

    for (final personal in [
      'Thandiwe',
      'THANDIWE',
      'Nkosi',
      'thandiwe@matric-compass.test',
      'sipho@x.test',
      'Sipho Dlamini',
      '45 000,00',
      '450,00',
      '0801015800083',
      '082 555 1234',
      jwt,
      '196.25.1.1',
      'refresh_token=abc123',
      'q=Nkosi',
    ]) {
      expect(sent, isNot(contains(personal)), reason: personal);
    }
  });

  test('what support needs survives it', () {
    final event = Scrubber(() => thandiwe).call(realistic(), Hint())!;

    expect(event.user?.id, 'user-42');
    expect(
      event.tags?['correlation_id'],
      '00-4bf92f3577b34da6a3ce929d0e0e4736-01',
    );
    expect(event.exceptions!.single.type, 'StateError');
    expect(event.breadcrumbs!.single.data?['status_code'], 500);
    expect(event.message!.formatted, contains('failed at [amount]'));
  });

  test('with nobody signed in, the patterns still apply', () {
    expect(
      Scrubber.scrubText('Paid R1 250.50 to x@y.co.za'),
      'Paid [amount] to [email]',
    );
  });
}
