import 'dart:convert';

/// Week 11 Day 2: what an access token says about who is signed in.
typedef TokenClaims = ({String email, String role, String? studentId});

/// Reads the claims in the middle part of a JWT, or null if [jwt] isn't one.
///
/// Reading is not checking. The middle part is base64-encoded JSON that
/// anyone holding the token can read; only the API can check the signature,
/// and it does, on every request. So the app uses these claims to choose a
/// shell and to ask for "my" data, never as permission for anything.
///
/// Matric Compass needs them because `/me` returns no student id: a
/// learner's id is the token's `student_id` claim, as web-next reads it.
TokenClaims? claimsOf(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) return null;
  try {
    final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final claims = jsonDecode(json);
    if (claims is! Map<String, Object?>) return null;
    final email = claims['email'];
    final role = claims['role'];
    if (email is! String || role is! String) return null;
    final studentId = claims['student_id'];
    return (
      email: email,
      role: role,
      studentId: studentId is String ? studentId : null,
    );
  } on FormatException {
    return null;
  }
}
