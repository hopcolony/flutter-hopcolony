import 'package:flutter/material.dart';
import 'package:hop_doc_example/screens/home.dart';
import 'package:hop_init/hop_init.dart' as init;

void main() async {
  await init.initialize();
  runApp(Root());
}

class Root extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
