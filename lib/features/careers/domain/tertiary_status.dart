/// Week 10 Day 1: a tertiary (university) application's status. Read-only in
/// the API, sent as a plain string, with [unknown] for anything newer.
enum TertiaryStatus {
  /// Still choosing.
  researching('Researching'),

  /// Application sent.
  applied('Applied'),

  /// Supporting documents sent.
  documentsSubmitted('DocumentsSubmitted'),

  /// The institution made an offer.
  offered('Offered'),

  /// The learner accepted the offer.
  accepted('Accepted'),

  /// Not successful.
  rejected('Rejected'),

  /// Anything this version of the app doesn't recognise.
  unknown('');

  new(this.apiName);

  /// The exact string the API sends.
  final String apiName;

  /// Maps the API's string to a status, falling back to [unknown].
  static TertiaryStatus fromApi(String value) => values.firstWhere(
    (status) => status != unknown && status.apiName == value,
    orElse: () => unknown,
  );
}
