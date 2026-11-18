/// Week 11 Day 2: the refresh token's value, taken from a response's
/// Set-Cookie headers by hand.
///
/// The API sends the refresh token only as a cookie:
/// `refresh_token=abc; expires=...; path=/api/v1/auth; secure; samesite=strict;
/// httponly`. A browser would keep it; a phone has no browser, so the app
/// reads the value and keeps it in secure storage. The attributes are a
/// browser's instructions and mean nothing here: the app itself sends the
/// token only to the auth endpoints.
///
/// Returns null when no header carries a cookie called [name], or when its
/// value is empty (a cookie being cleared).
String? refreshCookieFrom(List<String>? setCookieHeaders, String name) {
  for (final header in setCookieHeaders ?? const <String>[]) {
    // One header can hold several cookies on some servers, joined by
    // commas; an `expires` date has a comma too. Find our name directly.
    final start = header.indexOf('$name=');
    if (start < 0) continue;
    // Only a whole name counts: "xrefresh_token=" is someone else's.
    if (start > 0 && !' ,;'.contains(header[start - 1])) continue;
    final valueStart = start + name.length + 1;
    final end = header.indexOf(';', valueStart);
    final value =
        (end < 0
                ? header.substring(valueStart)
                : header.substring(valueStart, end))
            .trim();
    return value.isEmpty ? null : value;
  }
  return null;
}
