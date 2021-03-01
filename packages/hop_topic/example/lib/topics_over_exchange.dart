import 'package:flutter/material.dart';
import 'package:hop_topic/hop_topic.dart';
import 'package:random_color/random_color.dart';

class TopicsExchangeRow extends StatelessWidget {
  final _topics = HopTopic.instance;

  final String exchange = "oauth";
  final String topicDog = "topic-dog";
  final String topicCat = "topic-cat";

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StreamBuilder<dynamic>(
          stream: _topics.exchange(exchange).topic(topicDog).subscribe(),
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
          stream: _topics.exchange(exchange).topic(topicCat).subscribe(),
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
          stream: _topics.exchange(exchange).topic(topicDog).subscribe(),
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
          onPressed: () => _topics.exchange(exchange).topic(topicDog).send("Hello"),
          child: Text("Send to DOG Topic over Exchange"),
        ),
        TextButton(
          onPressed: () => _topics.exchange(exchange).topic(topicCat).send("Hello"),
          child: Text("Send to CAT topic over Exchange"),
        ),
      ],
    );
  }
}
