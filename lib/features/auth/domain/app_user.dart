/// Week 10 Day 3: the API's three roles. Matric Compass has one global role
/// per user, in the token, so the role can choose the whole shell.
enum Role {
  /// A learner: her own dashboard and applications.
  learner('Learner'),

  /// A counsellor: many learners, review and approve.
  counsellor('Counsellor'),

  /// An admin: the staff shell too.
  admin('Admin');

  new(this.label);

  /// The role in words, as shown on screen.
  final String label;

  /// Counsellors and admins share the staff shell.
  bool get isStaff => switch (this) {
    Role.learner => false,
    Role.counsellor || Role.admin => true,
  };
}

/// Week 10 Day 3: who is signed in. Week 11 Day 2 fills this from the API's
/// session; today it comes from a fake persona.
final class AppUser {
  /// Creates a user.
  const new({
    required this.email,
    required this.displayName,
    required this.role,
    this.studentId,
  });

  /// The sign-in email.
  final String email;

  /// What the app calls them.
  final String displayName;

  /// Their one global role.
  final Role role;

  /// The learner's student id; null for staff.
  final String? studentId;
}
