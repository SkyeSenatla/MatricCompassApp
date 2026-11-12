/// Week 10 Day 1: the API sends a bursary's status as a plain string
/// ("UnderReview"). The enum is ours, and so is [unknown]: a status the API
/// adds after this app was installed must not crash the screen.
enum BursaryStatus {
  /// The learner is still preparing it: edit, upload, submit.
  draft('Draft'),

  /// Sent to the counsellor; the learner waits.
  submitted('Submitted'),

  /// A counsellor is reviewing it.
  underReview('UnderReview'),

  /// Final: approved.
  approved('Approved'),

  /// Final: rejected.
  rejected('Rejected'),

  /// Anything this version of the app doesn't recognise.
  unknown('');

  new(this.apiName);

  /// The exact string the API sends.
  final String apiName;

  /// Week 10 Day 4: waiting for a counsellor. Moved here from the fake,
  /// where it was an `||` chain that a new status would slip past. Every
  /// value is listed, so a new status won't compile until someone decides.
  bool get isWaitingForReview => switch (this) {
    BursaryStatus.submitted || BursaryStatus.underReview => true,
    BursaryStatus.draft ||
    BursaryStatus.approved ||
    BursaryStatus.rejected ||
    BursaryStatus.unknown => false,
  };

  /// Maps the API's string to a status, falling back to [unknown].
  static BursaryStatus fromApi(String value) => values.firstWhere(
    (status) => status != unknown && status.apiName == value,
    orElse: () => unknown,
  );
}
