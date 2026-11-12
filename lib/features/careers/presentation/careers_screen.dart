import 'package:flutter/material.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';

/// Week 10 Day 3: the Careers tab has an address and a place in the shell
/// today. Day 4's capstone builds what's in it: aptitude tests and the
/// tertiary application pipeline.
class CareersScreen extends StatelessWidget {
  /// Creates the screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Careers')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.space4),
          child: Text(
            'Aptitude tests and university applications arrive here soon.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
