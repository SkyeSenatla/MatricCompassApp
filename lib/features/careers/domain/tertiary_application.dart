import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matric_compass/features/careers/domain/tertiary_status.dart';

part 'tertiary_application.freezed.dart';

/// Week 10 Day 4: one university application, shaped like the contract's
/// TertiaryApplicationResponse, with our status enum instead of a string.
///
/// Read-only: the API has no rule yet for who may move an application to
/// its next stage, so the app has no "what can I do next" switch for it.
@freezed
abstract class TertiaryApplication with _$TertiaryApplication {
  /// Creates an application.
  const factory({
    required String id,
    required String studentId,
    required String institutionName,
    required String programmeName,
    required TertiaryStatus status,
  }) = _TertiaryApplication;
}
