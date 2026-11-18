import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';

/// Week 11 Day 2: shown while the session is restored on launch, instead of
/// a sign-in screen that flashes and then jumps.
///
/// It never navigates itself: when the restore ends, the auth state
/// changes and the redirect moves on. If the API can't be reached, the
/// person is still signed in: they can try again, or choose to sign out.
class SplashScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: switch (auth) {
              Restoring(offline: true) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: AppTokens.space3),
                  Text(
                    "We can't reach Matric Compass.",
                    style: text.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.space2),
                  const Text(
                    "You're still signed in. Check your connection and try "
                    'again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTokens.space4),
                  FilledButton(
                    onPressed: controller.restore,
                    child: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: controller.signOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
              // Restoring, or a moment before the redirect moves on.
              _ => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppTokens.space3),
                  Text('Signing you in', style: text.titleMedium),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}
