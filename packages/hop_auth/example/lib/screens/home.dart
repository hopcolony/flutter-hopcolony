import 'package:flutter/material.dart';
import 'package:hop_auth/hop_auth.dart';

class HomePage extends StatelessWidget {
  final _auth = HopAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(_auth.currentUser.picture),
            Text(
              _auth.currentUser.email,
              style: TextStyle(
                fontSize: 24,
              ),
            ),
            Text(
              _auth.currentUser.name,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            Text(
              _auth.currentUser.uuid,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _auth.signOut(),
              child: Text('Sign-out'),
            ),
          ],
        ),
      ),
    );
  }
}
