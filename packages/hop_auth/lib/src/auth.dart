import 'dart:async';
import 'dart:html';
import 'package:hop_auth/src/hopcolony_provider.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'package:hop_auth/hop_auth.dart';
import 'package:hop_doc/hop_doc.dart';
import 'package:hop_topic/hop_topic.dart';
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
        ? await ref.update({"lastLoginTs": now})
        : await ref.setData({
            "registerTs": now,
            "lastLoginTs": now,
            "provider": credential.provider,
            "uuid": uuid,
            "email": credential.email,
            "name": credential.name,
            "picture": credential.picture,
            "locale": credential.locale,
            "isAnonymous": false,
          });

    currentUser = HopUser.fromJson(doc.doc.source);

    return AuthResult(success: true, user: currentUser);
  }

  Future<AuthResult> signInWithHopcolony({List<String> scopes}) async {
    Map<String, dynamic> queryParameters = {"client_id": init.config.identity};
    if (scopes != null) {
      queryParameters["scope"] = scopes.join(',');
    }

    // Open OAuth in another window
    Uri uri = Uri.parse("https://accounts.hopcolony.io")
        // Uri uri = Uri.parse("http://localhost:8080/o/oauth2/auth")
        .replace(queryParameters: queryParameters);
    this._oauthWindow = window.open(uri.toString(), "Hopcolony OAuth2");

    // Receive confirmation via topics
    Completer<AuthResult> loginCompleted = Completer<AuthResult>();
    StreamSubscription subscription = HopTopic.instance
        .exchange("oauth")
        .topic(init.config.identity)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) async {
      if (msg["success"]) {
        HopAuthCredential credential =
            HopAuthProvider.credential(idToken: msg["idToken"]);
        print(credential.idToken.payload);
        AuthResult result = await signInWithCredential(credential);
        loginCompleted.complete(result);
      } else {
        loginCompleted
            .complete(AuthResult(success: false, reason: msg["reason"]));
      }
      this._oauthWindow.close();
    });

    AuthResult result = await loginCompleted.future;
    subscription.cancel();

    return result;
  }
}
