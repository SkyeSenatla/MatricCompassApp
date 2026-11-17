import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/router/routes.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/app/widgets/failure_view.dart';
import 'package:matric_compass/core/errors/failure.dart';
import 'package:matric_compass/core/money/format_rands.dart';
import 'package:matric_compass/features/bursaries/presentation/bursary_status_chip.dart';
import 'package:matric_compass/features/students/domain/student.dart';
import 'package:matric_compass/features/students/presentation/students_providers.dart';

/// Week 10 Day 3: one student and her applications. Used on its own on a
/// phone, and beside the list on an expanded window. It needs only the id.
class StudentDetailPane extends ConsumerWidget {
  /// Creates the pane for student [id].
  const new({required this.id, super.key});

  /// The student's id.
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(studentProvider(id))) {
      AsyncData(:final value) => _Profile(profile: value),
      // Week 11 Day 1: the API's 404, as a Failure.
      AsyncError(error: NotFoundFailure()) => const Center(
        child: Text('Student not found.'),
      ),
      AsyncError(:final error) => FailureView(
        title: "We couldn't load this student.",
        error: error,
        onRetry: () => ref.invalidate(studentProvider(id)),
      ),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Profile extends StatelessWidget {
  const new({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final student = profile.student;
    return ListView(
      padding: const EdgeInsets.all(AppTokens.space4),
      children: [
        Text(student.fullName, style: text.headlineSmall),
        Text(student.learnerNumber, style: text.bodyLarge),
        const SizedBox(height: AppTokens.space4),
        Text('Bursary applications', style: text.titleMedium),
        const SizedBox(height: AppTokens.space2),
        if (profile.applications.isEmpty)
          const Text('None yet.')
        else
          for (final application in profile.applications)
            Card(
              child: ListTile(
                title: Text(application.funder),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: AppTokens.space1),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: BursaryStatusChip(application.status),
                  ),
                ),
                trailing: Text(formatRands(application.amount)),
                onTap: () =>
                    StaffApplicationRoute(id: application.id).go(context),
              ),
            ),
      ],
    );
  }
}
