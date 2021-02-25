import 'dart:async';
import 'dart:html';
import 'package:hop_init/hop_init.dart' as init;
import 'package:hop_auth/hop_auth.dart';
import 'package:hop_doc/hop_doc.dart';
import 'package:uuid/uuid.dart';

class HopAuth {
  HopUser currentUser;
  WindowBase _oauthWindow;
  static final HopAuth instance = HopAuth._internal();
  factory HopAuth() => instance;
  final HopDoc _docs = HopDoc.instance;
  HopAuth._internal();

  Future<AuthResult> signInWithCredential(AuthCredential credential) async {
    String uuid = Uuid().v5(credential.provider, credential.email);

    DocumentReference ref = _docs.index(".hop.auth").document(uuid);
    DocumentSnapshot doc = await ref.get();
    String now = DateTime.now().toString();
    doc = doc.success
        ? await ref.update({
            "lastLoginTs": now,
            "name": credential.name,
            "picture": credential.picture,
            "locale": credential.locale,
            "idToken": credential.idToken.toString(),
          })
        : await ref.setData({
            "registerTs": now,
            "lastLoginTs": now,
            "provider": credential.provider,
            "uuid": uuid,
            "email": credential.email,
            "name": credential.name,
            "picture": credential.picture,
            "locale": credential.locale,
            "idToken": credential.idToken.toString(),
            "isAnonymous": false,
          });

    currentUser = HopUser.fromJson(doc.doc.source);

    return AuthResult(user: currentUser);
  }

  Future<AuthResult> signInWithHopcolony() async {
    Uri uri = Uri.parse("http://localhost:8080/o/oauth2/auth").replace(
        queryParameters: {
          "redirect_uri": window.location.origin,
          "client_id": init.config.identity
        });
    this._oauthWindow = window.open(uri.toString(), "Hopcolony OAuth2");
    // Receive confirmation via topics
    Completer<Token> loginCompleted = Completer<Token>();
    // HopTopicConnection conn = topics.connection();
    // conn.subscribe("oauth/${init.config.identity}", (msg) {
    //   print(msg);
    //   if (msg["success"]) {
    //     loginCompleted.complete(Token(msg["idToken"]));
    //   } else {
    //     loginCompleted.complete(null);
    //   }
    // });
    Token idToken = await loginCompleted.future;
    print(idToken);
    this._oauthWindow.close();
    currentUser = HopUser(name: "Luis");
    return AuthResult(user: currentUser);
  }
}
