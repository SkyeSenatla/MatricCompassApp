import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';

/// Week 10 Day 1: what a person reads for each status. Exhaustive: a new
/// status is a compile error here until it has a label. Status is always
/// shown in words, never by colour alone.
extension BursaryStatusLabel on BursaryStatus {
  /// The label shown on screen.
  String get label => switch (this) {
    BursaryStatus.draft => 'Draft',
    BursaryStatus.submitted => 'Submitted',
    BursaryStatus.underReview => 'Under review',
    BursaryStatus.approved => 'Approved',
    BursaryStatus.rejected => 'Rejected',
    BursaryStatus.unknown => 'Status not recognised',
  };
}
