import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matric_compass/core/money/cents.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

part 'bursary_application.freezed.dart';

/// Week 10 Day 1: one bursary application, as the app means it.
///
/// It looks like the API's JSON, but the types are ours: a [BursaryStatus]
/// instead of a string, [Cents] instead of a bare int. freezed writes the
/// equality, hashCode, toString and copyWith we'd otherwise hand-write.
@freezed
abstract class BursaryApplication with _$BursaryApplication {
  /// Creates an application. Everything except [submittedAt] is required.
  const factory({
    required String id,
    required String studentId,
    required String funder,
    required Cents amount,
    required DateTime deadline,
    required BursaryStatus status,
    required List<String> requiredDocuments,
    required int version,
    DateTime? submittedAt,
  }) = _BursaryApplication;
}
