import 'package:flutter/material.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'package:hop_topic/hop_topic.dart';

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
  final HopTopic _topics = HopTopic.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hop Topics Example")),
      body: Center(
        child: Column(
          children: [
            StreamBuilder<dynamic>(
              stream:
                  _topics.exchange("oauth").listen(outputType: OutputType.JSON),
              builder: (_, snapshot) {
                if (snapshot.hasData) {
                  print(snapshot.data);
                  return Text(snapshot.data.toString());
                } else {
                  return Text("Nothing received yet");
                }
              },
            ),
            TextButton(
              onPressed: () => _topics
                  .exchange("oauth")
                  .topic("luis")
                  .send({"data": "Hello"}),
              child: Text("Send Hello to server"),
            )
          ],
        ),
      ),
    );
  }
}
