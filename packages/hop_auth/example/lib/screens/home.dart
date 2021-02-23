import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hop_auth/hop_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final HopAuth _auth = HopAuth.instance;

  Future<void> signOutGoogle() async {
    await googleSignIn.signOut();
    Navigator.of(context).popAndPushNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome ${_auth.currentUser.name}!"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: signOutGoogle,
          )
        ],
      ),
    );
  }
}
