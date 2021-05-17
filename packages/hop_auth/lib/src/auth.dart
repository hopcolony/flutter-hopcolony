import 'dart:async';
import 'dart:html';
import 'package:flutter/material.dart';
import 'package:hop_auth/src/hopcolony_provider.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'package:hop_auth/hop_auth.dart';
import 'package:hop_doc/hop_doc.dart';
import 'package:hop_topic/hop_topic.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HopAuthException implements Exception {
  String cause;
  HopAuthException(this.cause);
}

class HopAuth {
  Completer<bool> _isReadyCompleter = Completer<bool>();
  bool isInitilized = false;
  bool isReady = false;

  HopUser? currentUser;
  WindowBase? _oauthWindow;
  static final HopAuth instance = HopAuth._internal();
  factory HopAuth() => instance;
  final HopDoc _docs = HopDoc.instance;

  StreamController<HopUser?>? _authChangedController;

  HopAuth._internal() {
    if (!isInitilized) {
      initialize().then((_) {
        isReady = true;
        _isReadyCompleter.complete(true);
      });
      isInitilized = true;
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final uuid = await prefs.getString("hop.auth.uuid");
    if (uuid != null) {
      final snapshot = await _docs.index(".hop.auth").document(uuid).get();
      if (snapshot.success) {
        HopUser user = HopUser.fromJson(snapshot.doc!.source!);
        await setCurrentUser(user);
      }
    }
  }

  Future<bool> get ready async {
    return await _isReadyCompleter.future;
  }

  void dispose() {
    _authChangedController?.close();
  }

  Future<void> setCurrentUser(HopUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user != null) {
      await prefs.setString("hop.auth.uuid", user.uuid);
    } else {
      await prefs.remove("hop.auth.uuid");
    }

    currentUser = user;
    _authChangedController?.add(user);
  }

  Future<AuthResult> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    String uuid = Uuid().v5(Uuid.NAMESPACE_DNS, email);

    DocumentSnapshot doc = await _docs.index(".hop.auth").document(uuid).get();
    if (doc.success) {
      if (doc.doc!.source!.containsKey("password") &&
          doc.doc!.source!["password"] == password) {
        String now = DateTime.now().toString();
        await _docs
            .index(".hop.auth")
            .document(uuid)
            .update({"lastLoginTs": now});

        final user = HopUser.fromJson(doc.doc!.source!);
        await setCurrentUser(user);
        return AuthResult(success: true, user: user);
      }
      return AuthResult(success: false, reason: "Incorrect Password");
    }
    return AuthResult(success: false, reason: "Email does not exist");
  }

  Future<AuthResult> signInWithCredential(AuthCredential credential) async {
    String uuid = Uuid().v5(Uuid.NAMESPACE_DNS, credential.email);
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

    final user = HopUser.fromJson(doc.doc!.source!);
    await setCurrentUser(user);
    return AuthResult(success: true, user: user);
  }

  Future<AuthResult> signInWithHopcolony({List<String>? scopes}) async {
    Map<String, dynamic> queryParameters = {"client_id": init.config?.identity};
    if (scopes != null) {
      queryParameters["scope"] = scopes.join(',');
    }

    // Open OAuth in another window
    Uri uri = Uri.parse("https://accounts.hopcolony.io")
        .replace(queryParameters: queryParameters);
    this._oauthWindow = window.open(uri.toString(), "Hopcolony OAuth2");

    // Receive confirmation via topics
    Completer<AuthResult> loginCompleted = Completer<AuthResult>();
    StreamSubscription subscription = HopTopic.instance
        .exchange("oauth")
        .topic(init.config!.identity!)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) async {
      if (msg["success"]) {
        HopAuthCredential credential =
            HopAuthProvider.credential(idToken: msg["idToken"])
                as HopAuthCredential;
        AuthResult result = await signInWithCredential(credential);
        loginCompleted.complete(result);
      } else {
        loginCompleted
            .complete(AuthResult(success: false, reason: msg["reason"]));
      }
      this._oauthWindow?.close();
    });

    AuthResult result = await loginCompleted.future;
    subscription.cancel();

    if (!result.success) {
      throw HopAuthException(result.reason!);
    }

    await setCurrentUser(result.user);

    return result;
  }

  Future<void> signOut() async {
    setCurrentUser(null);
  }

  Stream<HopUser?> authChangeStream() {
    _authChangedController = StreamController<HopUser>(
        onListen: () async => _authChangedController!.add(currentUser),
        onResume: () async => _authChangedController!.add(currentUser));

    return _authChangedController!.stream;
  }

  Widget authChangeWidget({
    required Widget Function(HopUser?) onData,
    required Widget Function(String) onError,
    required Widget Function() onLoading,
  }) {
    return StreamBuilder<HopUser?>(
        stream: authChangeStream(),
        builder: (context, AsyncSnapshot<HopUser?> snapshot) {
          if (snapshot.connectionState == ConnectionState.active && isReady) {
            return onData(snapshot.data);
          }
          return onLoading();
        });
  }
}
