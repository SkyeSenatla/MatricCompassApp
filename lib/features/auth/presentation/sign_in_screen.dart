import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/app/app_config_provider.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/errors/result.dart';
import 'package:matric_compass/features/auth/data/fake_personas.dart';
import 'package:matric_compass/features/auth/presentation/auth_controller.dart';

/// Week 11 Day 2: the real sign-in, in every flavour.
///
/// It never navigates itself. Signing in changes the auth state; the
/// router's redirect hears that and sends the person on, to where they were
/// going or to their own shell.
class SignInScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _waiting = false;
  String? _error;
  Timer? _waitTimer;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _waitTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result case Err(:final failure)) {
        _error = switch (failure) {
          // The API answers 401 for an unknown email and a wrong password
          // alike, so the message doesn't say which.
          UnauthorizedFailure() => "That email and password don't match.",
          _ => failure.message,
        };
        // Week 11 Day 2: five tries a minute per address, then 429. Say
        // how long to wait (from Retry-After), and wait.
        if (failure case RateLimitedFailure(retryAfter: final wait?)) {
          _waiting = true;
          _waitTimer?.cancel();
          _waitTimer = Timer(wait, () {
            if (mounted) setState(() => _waiting = false);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isDev = ref.watch(appConfigProvider).flavor == Flavor.dev;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          Text('Welcome to Matric Compass', style: text.titleLarge),
          const SizedBox(height: AppTokens.space3),
          Form(
            key: _form,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'Enter your email.'
                        : null,
                  ),
                  const SizedBox(height: AppTokens.space3),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) =>
                        (value ?? '').isEmpty ? 'Enter your password.' : null,
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: AppTokens.space3),
                    // Read out as soon as it appears.
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTokens.space4),
                  FilledButton(
                    onPressed: _busy || _waiting ? null : _submit,
                    child: Text(_busy ? 'Signing in' : 'Sign in'),
                  ),
                ],
              ),
            ),
          ),
          // Dev flavour only: the seeded accounts' emails, one tap each. The
          // password is still typed: it never lives in the app.
          if (isDev) ...[
            const SizedBox(height: AppTokens.space4),
            Text('Seeded accounts (dev only)', style: text.labelLarge),
            const SizedBox(height: AppTokens.space2),
            Wrap(
              spacing: AppTokens.space2,
              runSpacing: AppTokens.space2,
              children: [
                for (final persona in FakePersonas.all)
                  ActionChip(
                    label: Text(persona.email),
                    onPressed: () => _email.text = persona.email,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
