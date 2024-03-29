import 'package:flutter/material.dart';
import 'package:hop_topic/hop_topic.dart';
import 'package:random_color/random_color.dart';

class BroadcastRow extends StatelessWidget {
  final _topics = HopTopic.instance;

  final String broadcastExchange = "broadcast";

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StreamBuilder<dynamic>(
          stream: _topics.exchange(broadcastExchange).subscribe(),
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
            );
          },
        ),
        StreamBuilder<dynamic>(
          stream: _topics.exchange(broadcastExchange).subscribe(),
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
            );
          },
        ),
        StreamBuilder<dynamic>(
          stream: _topics.exchange(broadcastExchange).subscribe(),
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
            );
          },
        ),
        TextButton(
          onPressed: () => _topics.exchange(broadcastExchange).send("Hello"),
          child: Text("Broadcast"),
        ),
      ],
    );
  }
}
