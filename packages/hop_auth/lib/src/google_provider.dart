import 'package:hop_auth/hop_auth.dart';

class GoogleAuthProvider {
  static AuthCredential credential({required String idToken}) =>
      GoogleAuthCredential(id: idToken);
}

class GoogleAuthCredential extends AuthCredential {
  GoogleAuthCredential({required String id})
      : super(provider: "Google", idToken: Token(id)) {
    this.email = idToken.payload["email"];
    this.name = idToken.payload["name"];
    this.picture = idToken.payload["picture"];
    this.locale = idToken.payload["locale"];
  }
}
