import 'package:flutter/material.dart';
import 'package:hop_topic/hop_topic.dart';
import 'package:random_color/random_color.dart';

class TopicsRow extends StatelessWidget {
  final _topics = HopTopic.instance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StreamBuilder<dynamic>(
          stream: _topics.topic("topic-dog").subscribe(),
          builder: (_, snapshot) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1),
                color: snapshot.hasData
                    ? RandomColor().randomColor()
                    : Colors.white,
              ),
              child: Center(child: Text("DOG")),
            );
          },
        ),
        StreamBuilder<dynamic>(
          stream: _topics.topic("topic-cat").subscribe(),
          builder: (_, snapshot) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1),
                color: snapshot.hasData
                    ? RandomColor().randomColor()
                    : Colors.white,
              ),
              child: Center(child: Text("CAT")),
            );
          },
        ),
        StreamBuilder<dynamic>(
          stream: _topics.topic("topic-dog").subscribe(),
          builder: (_, snapshot) {
            return Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1),
                color: snapshot.hasData
                    ? RandomColor().randomColor()
                    : Colors.white,
              ),
              child: Center(child: Text("DOG")),
            );
          },
        ),
        TextButton(
          onPressed: () => _topics.topic("topic-dog").send("Hello"),
          child: Text("Send to DOG"),
        ),
        TextButton(
          onPressed: () => _topics.topic("topic-cat").send("Hello"),
          child: Text("Send to CAT"),
        ),
      ],
    );
  }
}
