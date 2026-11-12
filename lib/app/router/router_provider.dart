import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:matric_compass/app/router/not_found_screen.dart';
import 'package:matric_compass/app/router/redirect.dart';
import 'package:matric_compass/app/router/routes.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router_provider.g.dart';

/// Week 10 Day 3: the app's one router.
///
/// The redirect must run again when the sign-in state changes, not only on
/// taps. go_router does that through a refreshListenable, which the
/// redirect docs don't mention: here a ValueNotifier mirrors the auth
/// provider, so signing in or out re-runs the gate at once.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final auth = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => auth.value = next);

  final router = GoRouter(
    initialLocation: const HomeRoute().location,
    routes: $appRoutes,
    refreshListenable: auth,
    redirect: (context, state) => redirectFor(auth.value, state.uri),
    // An address that matches no route.
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
  ref.onDispose(() {
    router.dispose();
    auth.dispose();
  });
  return router;
}
