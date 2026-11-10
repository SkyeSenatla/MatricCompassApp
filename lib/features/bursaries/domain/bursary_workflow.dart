import 'package:matric_compass/features/bursaries/domain/bursary_application.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

/// Something a learner can do to their own application.
enum LearnerAction {
  /// Change the amount or deadline.
  edit,

  /// Add or replace a supporting document.
  uploadDocuments,

  /// Send it to the counsellor.
  submit,
}

/// Week 10 Day 1: what a learner may do next, as one exhaustive match.
///
/// The app mirrors the API's rules so it can hide buttons that would fail;
/// the API still decides (409 for the wrong status, 422 after the deadline).
///
/// There is deliberately no `_` wildcard. When BursaryStatus gains a value,
/// this switch stops compiling until someone decides what it allows.
Set<LearnerAction> learnerActions(
  BursaryApplication application, {
  required DateTime now,
}) {
  // The API compares the deadline's UTC calendar date, not the instant.
  final deadlinePassed = _utcDate(now).isAfter(_utcDate(application.deadline));

  return switch ((application.status, deadlinePassed)) {
    (BursaryStatus.draft, false) => const {
      LearnerAction.edit,
      LearnerAction.uploadDocuments,
      LearnerAction.submit,
    },
    // Editing isn't checked against the deadline, but submitting is (422).
    (BursaryStatus.draft, true) => const {
      LearnerAction.edit,
      LearnerAction.uploadDocuments,
    },
    (
      BursaryStatus.submitted ||
          BursaryStatus.underReview ||
          BursaryStatus.approved ||
          BursaryStatus.rejected ||
          BursaryStatus.unknown,
      _,
    ) =>
      const {},
  };
}

DateTime _utcDate(DateTime instant) {
  final utc = instant.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}
