import 'package:flutter_test/flutter_test.dart';
import 'package:matric_compass/features/bursaries/domain/bursary_status.dart';
import 'package:matric_compass/features/careers/domain/tertiary_status.dart';

void main() {
  group('BursaryStatus.fromApi', () {
    test('maps every name the API sends', () {
      expect(BursaryStatus.fromApi('Draft'), BursaryStatus.draft);
      expect(BursaryStatus.fromApi('Submitted'), BursaryStatus.submitted);
      expect(BursaryStatus.fromApi('UnderReview'), BursaryStatus.underReview);
      expect(BursaryStatus.fromApi('Approved'), BursaryStatus.approved);
      expect(BursaryStatus.fromApi('Rejected'), BursaryStatus.rejected);
    });

    test('a status from a newer API is unknown, not a crash', () {
      expect(BursaryStatus.fromApi('Withdrawn'), BursaryStatus.unknown);
    });

    test('an empty string is unknown', () {
      expect(BursaryStatus.fromApi(''), BursaryStatus.unknown);
    });

    test('names are case-sensitive, as the API sends them', () {
      expect(BursaryStatus.fromApi('draft'), BursaryStatus.unknown);
    });
  });

  group('TertiaryStatus.fromApi', () {
    test('maps DocumentsSubmitted', () {
      expect(
        TertiaryStatus.fromApi('DocumentsSubmitted'),
        TertiaryStatus.documentsSubmitted,
      );
    });

    test('a status from a newer API is unknown', () {
      expect(TertiaryStatus.fromApi('Deferred'), TertiaryStatus.unknown);
    });
  });

  // Week 10 Day 4: the rule the staff Applications tab uses, moved from the
  // fake into the domain as an exhaustive switch.
  group('BursaryStatus.isWaitingForReview', () {
    test('submitted and under review are waiting', () {
      expect(BursaryStatus.submitted.isWaitingForReview, isTrue);
      expect(BursaryStatus.underReview.isWaitingForReview, isTrue);
    });

    test('every other status is not', () {
      for (final status in [
        BursaryStatus.draft,
        BursaryStatus.approved,
        BursaryStatus.rejected,
        BursaryStatus.unknown,
      ]) {
        expect(status.isWaitingForReview, isFalse, reason: status.name);
      }
    });
  });
}
