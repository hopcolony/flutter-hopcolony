import 'package:hop_auth/src/token.dart';

enum ProviderType {
  GOOGLE,
  FACEBOOK,
}

class AuthCredential {
  final String provider;
  final Token idToken;
  String? email, name, picture, locale;
  AuthCredential({required this.provider, required this.idToken});
}
