import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';

/// Week 10 Day 2: one bursary application by id.
abstract interface class BursaryRepository {
  /// The application, or a [BursaryNotFoundException].
  Future<BursaryApplication> fetchById(String id);
}

/// "Doesn't exist" and "isn't yours" look the same, as the API's 404 does.
/// Week 11 replaces exceptions with a Result and a sealed Failure.
final class BursaryNotFoundException implements Exception {
  /// Creates the exception for [id].
  const new(this.id);

  /// The id that wasn't found.
  final String id;

  @override
  String toString() => 'BursaryNotFoundException($id)';
}
