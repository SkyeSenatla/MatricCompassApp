import 'package:matric_compass/features/careers/domain/tertiary_status.dart';

/// Week 10 Day 4: what a person reads for each stage. Exhaustive, like the
/// bursary label: a new stage is a compile error here until it has words.
extension TertiaryStatusLabel on TertiaryStatus {
  /// The label shown on screen.
  String get label => switch (this) {
    TertiaryStatus.researching => 'Researching',
    TertiaryStatus.applied => 'Applied',
    TertiaryStatus.documentsSubmitted => 'Documents submitted',
    TertiaryStatus.offered => 'Offered',
    TertiaryStatus.accepted => 'Accepted',
    TertiaryStatus.rejected => 'Rejected',
    TertiaryStatus.unknown => 'Status not recognised',
  };
}
