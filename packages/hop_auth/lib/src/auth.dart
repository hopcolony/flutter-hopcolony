import 'package:hop_auth/hop_auth.dart';
import 'package:hop_doc/hop_doc.dart';
import 'package:uuid/uuid.dart';

class HopAuth {
  HopUser currentUser;
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
}
