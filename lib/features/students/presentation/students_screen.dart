import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/layout/window_size.dart';
import 'package:matric_compass/app/router/routes.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/features/students/presentation/student_detail_pane.dart';
import 'package:matric_compass/features/students/presentation/students_providers.dart';

/// Week 10 Day 3: the counsellor's students. On an expanded window (840 dp
/// and wider) the list and the selected student sit side by side; on
/// anything narrower it's the list alone, and the detail is its own page.
///
/// The address says what is selected (/staff/students/:id); the window
/// decides how it's shown. So rotating a tablet keeps the same student.
class StudentsScreen extends StatelessWidget {
  /// Creates the screen, with [selectedId] highlighted when set.
  const new({this.selectedId, super.key});

  /// The student in the address, if any.
  final String? selectedId;

  /// How wide the list pane is beside the detail.
  static const listPaneWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    final expanded = WindowSize.of(context) == WindowSize.expanded;
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: expanded
          ? Row(
              children: [
                SizedBox(
                  width: listPaneWidth,
                  child: _StudentList(selectedId: selectedId),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: switch (selectedId) {
                    final String id => StudentDetailPane(id: id),
                    null => const Center(child: Text('Choose a student.')),
                  },
                ),
              ],
            )
          : _StudentList(selectedId: selectedId),
    );
  }
}

class _StudentList extends ConsumerWidget {
  const new({required this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    return switch (students) {
      AsyncData(:final value) => ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
        children: [
          for (final student in value)
            ListTile(
              title: Text(student.fullName),
              subtitle: Text(student.learnerNumber),
              selected: student.id == selectedId,
              onTap: () => StudentDetailRoute(id: student.id).go(context),
            ),
        ],
      ),
      AsyncError() => const Center(child: Text("We couldn't load students.")),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }
}
