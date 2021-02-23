import 'package:flutter/material.dart';
import 'package:hop_doc_example/screens/home.dart';
import 'package:hop_init/hop_init.dart';

void main() {
  // Necessary to load the Hop configuration
  HopInit.instance.load(onConfigLoaded: () => runApp(Root()));
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
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomeScreen(),
      },
    );
  }
}