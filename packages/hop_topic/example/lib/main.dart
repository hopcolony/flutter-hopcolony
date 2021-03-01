import 'package:flutter/material.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'package:hop_topic_example/broadcast.dart';
import 'package:hop_topic_example/queues.dart';
import 'package:hop_topic_example/topics.dart';

void main() async {
  await init.initialize();
  runApp(Topics());
}

class Topics extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/home',
      routes: {
        '/home': (context) => Home(),
      },
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hop Topics Example")),
      body: Center(
        child: Column(
          children: [
            QueueRow(),
            TopicsRow(),
            BroadcastRow(),
          ],
        ),
      ),
    );
  }
}
