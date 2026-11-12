import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/features/auth/data/fake_personas.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';

/// Week 10 Day 3: a fake sign-in, one button per seeded account. Week 11
/// Day 2 replaces it with a real form against the API.
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
            'A fake sign-in until Week 11: the API seeds these three.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: AppTokens.space3),
          for (final persona in FakePersonas.all)
            Card(
              child: ListTile(
                title: Text(persona.displayName),
                subtitle: Text('${persona.role.label} · ${persona.email}'),
                trailing: const Icon(Icons.login),
                onTap: () => ref
                    .read(authControllerProvider.notifier)
                    .signIn(persona.email),
              ),
            ),
        ],
      ),
    );
  }
}
