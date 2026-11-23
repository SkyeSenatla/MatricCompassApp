import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matric_compass/app/layout/window_size.dart';
import 'package:matric_compass/app/router/routes.dart';
import 'package:matric_compass/app/theme/app_tokens.dart';
import 'package:matric_compass/features/students/domain/student.dart';
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
    // Week 12 Day 2: the list is const, so a new selectedId never rebuilds
    // it. The rows learn of the change through _Selection, and only the two
    // whose answer changed (the old student and the new) rebuild.
    final list = _Selection(
      selectedId: selectedId,
      child: const _StudentList(),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: expanded
          ? Row(
              children: [
                SizedBox(width: listPaneWidth, child: list),
                const VerticalDivider(width: 1),
                Expanded(
                  child: switch (selectedId) {
                    final String id => StudentDetailPane(id: id),
                    null => const Center(child: Text('Choose a student.')),
                  },
                ),
              ],
            )
          : list,
    );
  }
}

class _StudentList extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(studentsProvider);
    return switch (students) {
      // Week 12 Day 2: a builder makes rows as they scroll into view. The
      // prototype tells it every row's height without measuring each one,
      // and, unlike a fixed itemExtent, it follows the text size: at 200%
      // the rows grow instead of cutting their text off.
      AsyncData(:final value) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
        itemCount: value.length,
        prototypeItem: const ListTile(
          title: Text('Prototype learner'),
          subtitle: Text('LRN-0000-00000'),
        ),
        itemBuilder: (context, index) => StudentRow(value[index]),
      ),
      AsyncError() => const Center(child: Text("We couldn't load students.")),
      AsyncLoading() => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Week 12 Day 2: which student the address has selected, for the rows.
///
/// An InheritedModel lets each row depend on one aspect, its own student's
/// id: when the selection moves, Flutter rebuilds only the rows whose
/// aspect is the old or the new id. The same idea as Riverpod's select,
/// for a value that comes from the address, not a provider. DevTools
/// counted 17 rows rebuilt per tap before; now it's 2.
class _Selection extends InheritedModel<String> {
  const new({required this.selectedId, required super.child});

  final String? selectedId;

  /// Whether [id] is selected, rebuilding the caller only when that answer
  /// can have changed.
  static bool isSelected(BuildContext context, String id) =>
      InheritedModel.inheritFrom<_Selection>(context, aspect: id)?.selectedId ==
      id;

  @override
  bool updateShouldNotify(_Selection oldWidget) =>
      oldWidget.selectedId != selectedId;

  @override
  bool updateShouldNotifyDependent(
    _Selection oldWidget,
    Set<String> dependencies,
  ) =>
      dependencies.contains(oldWidget.selectedId) ||
      dependencies.contains(selectedId);
}

/// Week 12 Day 2: one student in the list: a widget of its own, so it can
/// rebuild on its own.
class StudentRow extends StatelessWidget {
  /// Creates the row for [student].
  const new(this.student, {super.key});

  /// Who this row shows.
  final Student student;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(student.fullName),
    subtitle: Text(student.learnerNumber),
    selected: _Selection.isSelected(context, student.id),
    onTap: () => StudentDetailRoute(id: student.id).go(context),
  );
}
