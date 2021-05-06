import 'package:flutter/material.dart';
import 'package:hop_auth/hop_auth.dart';

class HomePage extends StatelessWidget {
  final _auth = HopAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Home Page',
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          ElevatedButton(
            onPressed: () => _auth.signOut(),
            child: Text('Sign-out'),
          ),
        ],
      ),
    );
  }
}
