import 'package:sentry_flutter/sentry_flutter.dart';

/// Who is using the app right now, as far as the scrubber needs to know:
/// their name and email, so the scrubber can find them in free text.
typedef PersonInView = ({String name, String email});

/// Week 12 Day 2: POPIA on a phone. Every error report passes through here
/// on its way to Sentry (`beforeSend`), and leaves with nothing that says
/// who it was about.
///
/// What goes: the person's name and email wherever they appear, any email,
/// any token, any rand amount, any 13-digit ID number, any phone number,
/// the request and its headers and cookies, and every user field except the
/// id. What stays: what broke and where, the release, the environment, and
/// the correlation id, so support can find the same failure in the API.
///
/// A name can't be found by a pattern, so the signed-in person's own name is
/// passed in; other people's names must never be put in a message at all.
final class Scrubber {
  /// Creates the scrubber, with a function that answers who is signed in.
  new(this._personInView);

  final PersonInView? Function() _personInView;

  static final _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');
  static final _bearer = RegExp(r'Bearer\s+[\w.~+/=-]+', caseSensitive: false);
  // Three base64url parts: a JWT, wherever it turns up.
  static final _jwt = RegExp(r'eyJ[\w-]+\.[\w-]+\.[\w-]+');
  static final _rands = RegExp(r'R\s?\d[\d\s\u00A0]*(?:[.,]\d{2})?');
  static final _saIdNumber = RegExp(r'\b\d{13}\b');
  static final _phone = RegExp(r'(?:\+27|\b0)\d{2}[\s-]?\d{3}[\s-]?\d{4}\b');
  // A URL's query string can carry anything (?email=…, ?q=Nkosi); its path
  // is ours. The scrubber test found one in a breadcrumb's message.
  static final _query = RegExp(r'\?[^\s#"]*');

  // Breadcrumb data that may carry a person, whatever the integration.
  static const _droppedKeys = {
    'body',
    'data',
    'request_body',
    'response_body',
    'headers',
    'cookies',
    'authorization',
    'query',
  };

  /// For `SentryFlutterOptions.beforeSend`.
  SentryEvent? call(SentryEvent event, Hint hint) {
    final person = _personInView();
    String clean(String text) => scrubText(text, person);

    event
      ..request = null
      ..serverName = null
      // The id is a random string that means nothing outside our database.
      ..user = switch (event.user?.id) {
        final String id => SentryUser(id: id),
        null => null,
      };

    if (event.message case final message?) {
      message
        ..formatted = clean(message.formatted)
        ..template = switch (message.template) {
          final String template => clean(template),
          null => null,
        }
        ..params = null;
    }
    for (final exception in event.exceptions ?? const <SentryException>[]) {
      if (exception.value case final String value) {
        exception.value = clean(value);
      }
    }
    for (final crumb in event.breadcrumbs ?? const <Breadcrumb>[]) {
      if (crumb.message case final String message) {
        crumb.message = clean(message);
      }
      crumb.data = switch (crumb.data) {
        final Map<String, dynamic> data => {
          for (final MapEntry(:key, :value) in data.entries)
            if (!_droppedKeys.contains(key.toLowerCase()))
              key: value is String ? clean(value) : value,
        },
        null => null,
      };
    }
    if (event.tags case final Map<String, String> tags) {
      event.tags = {
        for (final MapEntry(:key, :value) in tags.entries) key: clean(value),
      };
    }
    return event;
  }

  /// Replaces everything personal in [text]. Public so a test can feed it
  /// sentences directly.
  static String scrubText(String text, [PersonInView? person]) {
    var result = text;
    if (person != null) {
      if (person.email.isNotEmpty) {
        result = result.replaceAll(person.email, '[email]');
      }
      if (person.name.isNotEmpty) {
        result = result.replaceAll(
          RegExp(RegExp.escape(person.name), caseSensitive: false),
          '[name]',
        );
      }
    }
    return result
        .replaceAll(_query, '?[query]')
        .replaceAll(_bearer, 'Bearer [token]')
        .replaceAll(_jwt, '[token]')
        .replaceAll(_email, '[email]')
        .replaceAll(_saIdNumber, '[id number]')
        .replaceAll(_phone, '[phone]')
        .replaceAll(_rands, '[amount]');
  }
}
