import 'package:hop_auth/hop_auth.dart';

class HopAuthProvider {
  static AuthCredential credential({String idToken}) =>
      HopAuthCredential(id: idToken);
}

class HopAuthCredential extends AuthCredential {
  HopAuthCredential({String id})
      : super(provider: "Hopcolony", idToken: Token(id)) {
    this.email = idToken.payload["email"];
    this.name = idToken.payload["name"];
    this.picture = idToken.payload["picture"];
    this.locale = idToken.payload["locale"];
  }
}
