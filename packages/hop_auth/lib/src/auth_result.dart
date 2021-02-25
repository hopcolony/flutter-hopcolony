import 'package:hop_auth/src/user.dart';

class AuthResult {
  final bool success;
  final String reason;
  final HopUser user;
  AuthResult({this.success, this.reason, this.user});
}
