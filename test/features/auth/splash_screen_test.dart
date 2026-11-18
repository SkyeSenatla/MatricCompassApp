import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:matric_compass/features/auth/presentation/splash_screen.dart';

/// What the buttons asked for.
class _Taps {
  int restores = 0;
  int signOuts = 0;
}

/// A controller stuck in one state, counting what the buttons asked for.
class _Stuck extends AuthController {
  new(this._state, this._taps);

  final AuthState _state;
  final _Taps _taps;

  @override
  AuthState build() => _state;

  @override
  Future<void> restore() async => _taps.restores++;

  @override
  Future<void> signOut() async => _taps.signOuts++;
}

void main() {
  testWidgets('while restoring: a spinner, never the sign-in form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _Stuck(const Restoring(), _Taps()),
          ),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Signing you in'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('offline: still signed in, with Try again and Sign out', (
    tester,
  ) async {
    final taps = _Taps();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => _Stuck(const Restoring(offline: true), taps),
          ),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    expect(find.text("We can't reach Matric Compass."), findsOneWidget);
    expect(find.textContaining("You're still signed in"), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.tap(find.text('Sign out'));

    expect(taps.restores, 1);
    expect(taps.signOuts, 1);
  });
}
