import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/auth/data/fake_personas.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';

/// Week 10 Day 3: one button per seeded account. Week 11 Day 1: on the API
/// each button signs in for real (dev only, with the seed password). Week
/// 11 Day 2 replaces it with a real form.
///
/// It never navigates itself. Signing in changes the auth state; the
/// router's redirect hears that and sends the person on, to where they were
/// going or to their own shell.
class SignInScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          Text('Choose an account', style: text.titleLarge),
          const SizedBox(height: AppTokens.space2),
          Text(
            "The API's three seeded accounts. A dev-only stand-in until "
            'tomorrow.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppTokens.space3),
          for (final persona in FakePersonas.all)
            Card(
              child: ListTile(
                title: Text(persona.displayName),
                subtitle: Text('${persona.role.label} · ${persona.email}'),
                trailing: const Icon(Icons.login),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final result = await ref
                      .read(authControllerProvider.notifier)
                      .signIn(persona.email);
                  // Week 11 Day 1: a wrong password, a 429 or no API shows
                  // the Failure's own words.
                  if (result case Err(:final failure)) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(failure.message)),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
