import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';

/// Week 10 Day 3: an address that matches no screen, such as a link with a
/// typo. Not a crash, and a way home.
class NotFoundScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Page not found.', textAlign: TextAlign.center),
              const SizedBox(height: AppTokens.space3),
              // The redirect sends "/" to the right shell's first tab.
              FilledButton(
                onPressed: () => context.go('/'),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
