import 'package:flutter/material.dart';
import 'package:matric_compass/app/layout/window_size.dart';
import 'package:matric_compass/features/students/presentation/student_detail_pane.dart';
import 'package:matric_compass/features/students/presentation/students_screen.dart';

/// Week 10 Day 3: what /staff/students/:id shows. It asks the window on
/// every build, so crossing 840 dp while it's open (rotating a tablet,
/// split screen) swaps the layout and keeps the student.
class StudentDetailPage extends StatelessWidget {
  /// Creates the page for student [id].
  const new({required this.id, super.key});

  /// The student in the address.
  final String id;

  @override
  Widget build(BuildContext context) {
    return switch (WindowSize.of(context)) {
      WindowSize.expanded => StudentsScreen(selectedId: id),
      WindowSize.compact || WindowSize.medium => Scaffold(
        appBar: AppBar(title: const Text('Student')),
        body: StudentDetailPane(id: id),
      ),
    };
  }
}
