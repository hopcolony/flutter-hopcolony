import 'package:flutter/material.dart';
import 'package:hop_auth/hop_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  HopAuth _auth = HopAuth.instance;

  Future<void> signInWithHopcolony() async {
    final AuthResult result =
        await _auth.signInWithHopcolony(scopes: ["projects"]);
    if (result.success)
      Navigator.of(context).popAndPushNamed('/home');
    else
      print("[ERROR FROM LOGIN] ${result.reason}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: TextButton(
          onPressed: signInWithHopcolony,
          child: Text("Sign in with Hopcolony"),
        ),
      ),
    );
  }
}
