import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:hop_topic/hop_topic.dart';
import 'package:hop_init/hop_init.dart' as init;

void main() async {
  final String userName = "core@hopcolony.io";
  final String projectName = "core";
  final String tokenName = "supersecret";

  final String topicDog = "topic-dog";
  final String topicCat = "topic-cat";
  final String queueName = "processing-queue";
  final String broadcastExchange = "broadcast";
  final String topicExchange = "oauth";
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

  test('Subscriber Publisher Topic Dog', () async {
    HopTopic.instance
        .topic(topicDog)
        .subscribe(outputType: OutputType.STRING)
        .listen((msg) {
      expect(msg, dataString);
    });
    await Future.delayed(Duration(milliseconds: 100));
    HopTopic.instance.topic(topicDog).send(dataString);
    await Future.delayed(Duration(milliseconds: 300));
    HopTopic.instance.closeOpenConnections();
  });

  test('Subscriber Publisher Topic Cat', () async {
    HopTopic.instance
        .topic(topicCat)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      expect(msg, dataJson);
    });
    await Future.delayed(Duration(milliseconds: 100));
    HopTopic.instance.topic(topicCat).send(dataJson);
    await Future.delayed(Duration(milliseconds: 300));
    HopTopic.instance.closeOpenConnections();
  });

  test('Subscriber Publisher Queue', () async {
    HopTopic.instance
        .queue(queueName)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      expect(msg, dataJson);
    });
    HopTopic.instance
        .queue(queueName)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      expect(msg, dataJson);
    });
    await Future.delayed(Duration(milliseconds: 100));
    HopTopic.instance.queue(queueName).send(dataJson);
    HopTopic.instance.queue(queueName).send(dataJson);
    await Future.delayed(Duration(milliseconds: 300));
    HopTopic.instance.closeOpenConnections();
  });

  test('Subscriber Publisher Broadcast', () async {
    HopTopic.instance
        .exchange(broadcastExchange)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      expect(msg, dataJson);
    });
    HopTopic.instance
        .exchange(broadcastExchange)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      expect(msg, dataJson);
    });
    await Future.delayed(Duration(milliseconds: 100));
    HopTopic.instance.exchange(broadcastExchange).send(dataJson);
    await Future.delayed(Duration(milliseconds: 300));
    HopTopic.instance.closeOpenConnections();
  });

  test('Subscriber Publisher Topic Over Exchange', () async {
    HopTopic.instance
        .exchange(topicExchange)
        .topic(topicCat)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      // print(msg);
      expect(msg, dataJson);
    });
    await Future.delayed(Duration(milliseconds: 100));
    HopTopic.instance.exchange(topicExchange).topic(topicCat).send(dataJson);
    await Future.delayed(Duration(milliseconds: 300));
    HopTopic.instance.closeOpenConnections();
  });
}
