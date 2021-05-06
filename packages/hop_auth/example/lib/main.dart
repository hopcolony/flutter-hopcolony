import 'package:hop_auth/hop_auth.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'package:hop_auth_example/screens/home.dart';
import 'package:hop_auth_example/screens/login.dart';
import 'package:flutter/material.dart';

void main() async {
  await init.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StartPage(),
    );
  }
}

class StartPage extends StatelessWidget {
  final _auth = HopAuth.instance;
  @override
  Widget build(BuildContext context) {
    return _auth.authChangeWidget(onData: (data) {
      if (data != null) {
        return HomePage();
      }
      return LoginPage();
    }, onError: (reason) {
      return Scaffold(
        body: Center(child: Text(reason)),
      );
    }, onLoading: () {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    });
  }
}
