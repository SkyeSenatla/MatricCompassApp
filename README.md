# Matric Compass (Flutter)

The learner and counsellor app for the Matric Compass API.

## Running it against the API

1. Start the API from the `Matric-Compass` repo: `docker compose up -d`.
   For a clean demo, start from a fresh database first:
   `docker compose down -v` (this deletes the local data).
2. Run the dev flavour:

   ```bash
   flutter run --flavor dev --dart-define-from-file=config/dev.json
   ```

3. Sign in with a seeded account and the seed password from the API's
   `.env` (`SEED_USERS_PASSWORD`). The dev flavour offers the seeded emails
   as chips; the password is always typed, never stored in the app.

On a real phone, put your laptop's LAN address in `config/dev.json` and in
`android/app/src/dev/res/xml/network_security_config.xml`.

## The session (Week 11 Day 2)

- The **access token** (5 minutes) lives in memory only. The **refresh
  token** arrives as the `refresh_token` cookie, which the app reads from
  `Set-Cookie` by hand and keeps in `flutter_secure_storage`. The cookie's
  name comes from `REFRESH_COOKIE_NAME` in `config/*.json`.
- Every request goes through `SessionInterceptor`, a `QueuedInterceptor`.
  It refreshes a minute before the token expires, and on a 401 refreshes
  once and sends the request again once. A second 401 that arrives after a
  refresh is sent again with the new token instead of refreshing again,
  because the API's reuse detection would end the session.
- Only the refresh endpoint's own 401 signs anyone out. A 403, or no
  network, never does.
- On launch the app is `Restoring` (a splash screen) while one refresh
  checks the stored session. Offline, it waits on the splash, still signed
  in.
- Sign-out wipes the phone first (both tokens, and every user-scoped
  provider through the auth state), then tells the API.
- Android backup is off (`android:allowBackup="false"`): a restored backup
  arrives without the Keystore key that unlocks secure storage.

## The API client

The client in `lib/core/api/generated/` is generated from
`contract/openapi/v1.json` by swagger_parser, and committed:

```bash
rm -rf lib/core/api/generated
dart run swagger_parser
dart format lib/core/api/generated
dart run build_runner build
```

CI generates it again and fails if anything differs, so the client can't
drift from the contract copy. Only the endpoints the app calls are generated
(`include_paths` in `swagger_parser.yaml`).

The three auth calls (login, refresh, logout) don't use the generated
client: it returns only the body, and the refresh token arrives in a
header. `lib/features/auth/data/auth_api.dart` calls them with Dio directly,
using the generated models.

## Decisions

- **Repositories return `Result<T>` (a sealed class, `Ok` or `Err`), not
  Dart 3 records.** A sealed class gives the two cases names a switch can
  match, and is what Flutter's architecture guide uses. Providers unwrap it
  with `valueOrThrow`, so screens get an `AsyncError` holding a `Failure`.
- **Every error becomes one sealed `Failure`, in one place**
  (`lib/core/errors/failure_mapping.dart`). No presentation or domain file
  imports Dio; `test/architecture/design_rules_test.dart` checks it.
- **Only "no answer" is retried automatically.** A 500 has already been
  retried inside the API, so it is shown at once with its reference.
- **Generated code from build_runner (`*.g.dart`, `*.freezed.dart`) is not
  committed**; CI makes it.
- **`dependency_overrides` holds back two iOS packages** that
  flutter_secure_storage pulls in, whose newest releases were under two
  weeks old on 17 November 2026. Remove the overrides after 25 November.

## Tests

```bash
flutter test                          # everything except the live tests
flutter test --run-skipped --tags live --dart-define=SEED_PASSWORD=<seed password>
```

The live tests call the real API (on `localhost:5146`). They sign in five
times, the API's limit per minute, so run them once at a time. The Week 11
Day 1 test expects a fresh database.
