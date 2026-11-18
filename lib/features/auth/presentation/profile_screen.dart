import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';

/// Week 10 Day 3: who is signed in, and the way out. Both shells use it.
///
/// Week 11 Day 2: in the dev flavour, two buttons for the session demo.
class ProfileScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final isDev = ref.watch(appConfigProvider).flavor == Flavor.dev;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: switch (auth) {
        SignedIn(:final user) => ListView(
          padding: const EdgeInsets.all(AppTokens.space4),
          children: [
            Text(user.displayName, style: text.headlineSmall),
            const SizedBox(height: AppTokens.space1),
            // On the API the name isn't in the token, so the display name
            // is the email: don't say it twice.
            if (user.email != user.displayName)
              Text(user.email, style: text.bodyLarge),
            Text(user.role.label, style: text.bodyLarge),
            const SizedBox(height: AppTokens.space4),
            // The redirect hears the change and sends the app to sign-in.
            FilledButton(
              onPressed: controller.signOut,
              child: const Text('Sign out'),
            ),
            if (isDev) ...[
              const SizedBox(height: AppTokens.space4),
              Text('Session demo (dev only)', style: text.titleMedium),
              const SizedBox(height: AppTokens.space2),
              OutlinedButton(
                onPressed: controller.spoilAccessTokenForDemo,
                child: const Text('Spoil my access token'),
              ),
              const SizedBox(height: AppTokens.space2),
              OutlinedButton(
                onPressed: controller.expireAccessTokenForDemo,
                child: const Text('Expire my access token now'),
              ),
            ],
          ],
        ),
        // Only for a moment: the redirect is already on its way.
        Restoring() || SignedOut() => const SizedBox.shrink(),
      },
    );
  }
}
