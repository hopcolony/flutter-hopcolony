import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hop_topic/hop_topic.dart';
import 'package:hop_init/hop_init.dart' as init;

void main() async {
  final String userName = "console@hopcolony.io";
  final String projectName = "console";
  final String tokenName = "supersecret";

  final String topic = "test-topic2";
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
    StreamSubscription<dynamic> subscription = HopTopic.instance
        .topic(topic)
        .listen(outputType: OutputType.STRING)
        .listen((msg) => expect(msg, dataString));
    await Future.delayed(Duration(milliseconds: 100));
    HopTopic.instance.topic(topic).send(dataString);
    await Future.delayed(Duration(milliseconds: 300));
    subscription.cancel();
  });

  test('Subscriber Publisher Json', () async {
    StreamSubscription<dynamic> subscription = HopTopic.instance
        .topic(topic)
        .listen(outputType: OutputType.JSON)
        .listen((msg) => expect(msg, dataJson));
    await Future.delayed(Duration(milliseconds: 100));
    HopTopic.instance.topic(topic).send(dataJson);
    await Future.delayed(Duration(milliseconds: 300));
    subscription.cancel();
  });
}
