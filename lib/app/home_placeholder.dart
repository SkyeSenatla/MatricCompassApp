import 'package:flutter/material.dart';
import 'package:matric_compass/app/app_config.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/core/money/format_rands.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_status_label.dart';

/// Week 10 Day 1 only: proves the flavour, the config and the domain reach
/// the screen. Day 2 replaces it with the learner dashboard.
class HomePlaceholder extends StatelessWidget {
  /// Creates the placeholder.
  const new({required this.config, super.key});

  /// The build's settings.
  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Matric Compass')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Flavour: ${config.flavor.name}', style: text.titleMedium),
          Text('API: ${config.apiBaseUrl}', style: text.bodyMedium),
          const SizedBox(height: 24),
          Text(formatRands(const Cents(4500000)), style: text.headlineMedium),
          Text(BursaryStatus.fromApi('UnderReview').label),
          Text(BursaryStatus.fromApi('Withdrawn').label),
        ],
      ),
    );
  }
}
