# Matric Compass (Flutter)

The learner and counsellor app for the Matric Compass API.

## Running it against the API (Week 11 Day 1)

1. Start the API from the `Matric-Compass` repo: `docker compose up -d`.
   For a clean demo, start from a fresh database first:
   `docker compose down -v` (this deletes the local data).
2. Run the dev flavour with the seed password from the API's `.env`
   (`SEED_USERS_PASSWORD`). It is passed in, never committed:

   ```bash
   flutter run --flavor dev --dart-define-from-file=config/dev.json \
     --dart-define=DEV_PASSWORD=<seed password>
   ```

The dev sign-in is a stand-in until Week 11 Day 2: the access token lasts
5 minutes, and after that the app sends you back to sign-in.

On a real phone, put your laptop's LAN address in `config/dev.json` and in
`android/app/src/dev/res/xml/network_security_config.xml`.

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

## Tests

```bash
flutter test                          # everything except the live tests
flutter test --run-skipped --tags live --dart-define=DEV_PASSWORD=<seed password>
```

The live tests call the real API (on `localhost:5146`) and expect a fresh
database.
