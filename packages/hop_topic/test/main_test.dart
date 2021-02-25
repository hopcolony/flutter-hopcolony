import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hop_topic/hop_topic.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'package:hop_topic/src/subscriber.dart';

void main() async {
  final String userName = "console@hopcolony.io";
  final String projectName = "console";
  final String tokenName = "supersecret";

  final String topic = "test-topic";
  final String dataString = "Test Message";
  final Map<String, dynamic> dataJson = {"data": "Testing Hop Topics!"};

  init.Project project;

  setUpAll(() async {
    project = await init.initialize(
        username: userName, project: projectName, token: tokenName);
  });

  test('Initialize', () {
    expect(project.config, isNot(null));
    expect(project.name, projectName);

    expect(HopTopic.instance.project.name, project.name);
    expect(HopTopic.instance.host, "topics.hopcolony.io");
    expect(HopTopic.instance.identity, project.config.identity);
  });

  test('Subscriber Publisher String', () async {
    HopTopicPublisher pub = HopTopic.instance.publisher(topic);
    StreamSubscription<dynamic> subscription = HopTopic.instance
        .subscribe(topic, outputType: OutputType.STRING)
        .stream
        .listen((msg) => expect(msg, dataString));
    await pub.send(dataString);
    await Future.delayed(Duration(milliseconds: 300));
    pub.close();
    subscription.cancel();
  });

  test('Subscriber Publisher Json', () async {
    HopTopicPublisher pub = HopTopic.instance.publisher(topic);
    StreamSubscription<dynamic> subscription = HopTopic.instance
        .subscribe(topic, outputType: OutputType.JSON)
        .stream
        .listen((msg) => expect(msg, dataJson));
    await pub.send(dataJson);
    await Future.delayed(Duration(milliseconds: 300));
    pub.close();
    subscription.cancel();
  });
}
