import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/core/network/refresh_cookie.dart';

void main() {
  // The header exactly as the Matric Compass API sent it on 17 November
  // 2026, with the value replaced.
  const fromTheApi =
      'refresh_token=abc_DEF-123; expires=Tue, 24 Nov 2026 10:35:38 GMT; '
      'path=/api/v1/auth; secure; samesite=strict; httponly';

  test("reads the value from the API's Set-Cookie header", () {
    expect(refreshCookieFrom([fromTheApi], 'refresh_token'), 'abc_DEF-123');
  });

  test('finds it among other cookies', () {
    expect(
      refreshCookieFrom([
        'theme=dark; path=/',
        'session=x, refresh_token=second; path=/api/v1/auth',
      ], 'refresh_token'),
      'second',
    );
  });

  test("a cookie whose name only ends the same is someone else's", () {
    expect(
      refreshCookieFrom(['xrefresh_token=nope; path=/'], 'refresh_token'),
      isNull,
    );
  });

  test('the name comes from configuration', () {
    expect(
      refreshCookieFrom(['rt=stokvel; path=/api/v1/auth'], 'rt'),
      'stokvel',
    );
    expect(refreshCookieFrom([fromTheApi], 'rt'), isNull);
  });

  test('no header, or a cookie being cleared, gives null', () {
    expect(refreshCookieFrom(null, 'refresh_token'), isNull);
    expect(
      refreshCookieFrom([
        'refresh_token=; expires=Thu, 01 Jan 1970 00:00:00 GMT',
      ], 'refresh_token'),
      isNull,
    );
  });
}
