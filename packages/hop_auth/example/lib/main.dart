import 'package:flutter/material.dart';
import 'package:hop_auth_example/screens/home.dart';
import 'package:hop_auth_example/screens/login.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:hop_init/hop_init.dart' as init;

void main() async {
  setUrlStrategy(PathUrlStrategy());
  await init.initialize();
  runApp(Root());
}

class Root extends StatefulWidget {
  @override
  RootState createState() => RootState();
}

class RootState extends State<Root> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      onUnknownRoute: (settings) =>
          MaterialPageRoute(builder: (_) => LoginScreen()),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
