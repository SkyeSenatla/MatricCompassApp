import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/settings/theme_setting.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/features/auth/domain/auth_state.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_edit.dart';

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
    final themeMode = ref.watch(themeSettingProvider);
    final unsaved = ref.watch(pendingEditCountProvider).value ?? 0;

    // Week 11 Day 3: sign-out empties the phone, pending edits too. An edit
    // not yet saved is something the person believes they did: ask first.
    Future<void> signOut() async {
      if (unsaved > 0) {
        final sure = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: const Text('Sign out and lose your change?'),
            content: const Text(
              "You have a change that hasn't been saved yet. Signing out "
              'removes it from this phone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(false),
                child: const Text('Stay signed in'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(true),
                child: const Text('Sign out'),
              ),
            ],
          ),
        );
        if (sure != true) return;
      }
      await controller.signOut();
    }

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
            // Week 11 Day 3: a setting of the phone's, so it survives
            // sign-out.
            Text('Theme', style: text.titleMedium),
            const SizedBox(height: AppTokens.space2),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {themeMode},
              onSelectionChanged: (choice) =>
                  ref.read(themeSettingProvider.notifier).choose(choice.single),
            ),
            const SizedBox(height: AppTokens.space4),
            // The redirect hears the change and sends the app to sign-in.
            FilledButton(onPressed: signOut, child: const Text('Sign out')),
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
