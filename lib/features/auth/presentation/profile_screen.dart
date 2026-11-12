import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';

/// Week 10 Day 3: who is signed in, and the way out. Both shells use it.
class ProfileScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: switch (auth) {
        SignedIn(:final user) => ListView(
          padding: const EdgeInsets.all(AppTokens.space4),
          children: [
            Text(user.displayName, style: text.headlineSmall),
            const SizedBox(height: AppTokens.space1),
            Text(user.email, style: text.bodyLarge),
            Text(user.role.label, style: text.bodyLarge),
            const SizedBox(height: AppTokens.space4),
            // The redirect hears the change and sends the app to sign-in.
            FilledButton(
              onPressed: ref.read(authControllerProvider.notifier).signOut,
              child: const Text('Sign out'),
            ),
          ],
        ),
        // Only for a moment: the redirect is already on its way.
        SignedOut() => const SizedBox.shrink(),
      },
    );
  }
}
