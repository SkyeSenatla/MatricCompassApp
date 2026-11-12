import 'package:matric_compass/core/fakes/seed.dart';
import 'package:matric_compass/features/auth/domain/app_user.dart';

/// Week 10 Day 3: the API's three seeded accounts, one per role, with the
/// same emails. No passwords: signing in is a fake switch until Week 11.
abstract final class FakePersonas {
  /// Thandiwe, the learner.
  static const thandiwe = AppUser(
    email: 'thandiwe@matric-compass.test',
    displayName: Seed.thandiweName,
    role: Role.learner,
    studentId: Seed.thandiweId,
  );

  /// The counsellor.
  static const counsellor = AppUser(
    email: 'counsellor@matric-compass.test',
    displayName: 'Counsellor',
    role: Role.counsellor,
  );

  /// The admin.
  static const admin = AppUser(
    email: 'admin@matric-compass.test',
    displayName: 'Admin',
    role: Role.admin,
  );

  /// All three, in the order the sign-in screen lists them.
  static const List<AppUser> all = [thandiwe, counsellor, admin];
}
