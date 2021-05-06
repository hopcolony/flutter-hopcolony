import 'package:hop_auth/hop_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final _auth = HopAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Login',
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          ElevatedButton(
            onPressed: _auth.signInWithHopcolony,
            child: Text('Sign-in with Hopcolony'),
          ),
        ],
      ),
    );
  }
}
