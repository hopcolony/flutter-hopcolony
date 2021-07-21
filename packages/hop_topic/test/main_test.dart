import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_test/flutter_test.dart';
import 'package:hop_topic/hop_topic.dart';
import 'package:hop_init/hop_init.dart' as init;

void main() async {
  final String? userName = Platform.environment['HOP_USERNAME'];
  final String? projectName = Platform.environment['HOP_PROJECT'];
  final String? tokenName = Platform.environment['HOP_TOKEN'];

  final String topicDog = "topic-dog";
  final String topicCat = "topic-cat";
  final String queueName = "processing-queue";
  final String broadcastExchange = "broadcast";
  final String topicExchange = "oauth";
  final String dataString = "Test Message";
  final Map<String, dynamic> dataJson = {"data": "Testing Hop Topics!"};

  late init.Project project;

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
    Completer<String> completer = Completer<String>();
    HopTopic.instance
        .topic(topicDog)
        .subscribe(outputType: OutputType.STRING)
        .listen((msg) {
      completer.complete(msg);
    });

    await Future.delayed(Duration(milliseconds: 300));
    HopTopic.instance.topic(topicDog).send(dataString);
    await Future.delayed(Duration(milliseconds: 100));
    expect(await completer.future, dataString);
    HopTopic.instance.closeOpenConnections();
  });

  test('Subscriber Publisher Topic Cat', () async {
    Completer<Map> completer = Completer<Map>();
    HopTopic.instance
        .topic(topicCat)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      completer.complete(msg);
    });
    await Future.delayed(Duration(milliseconds: 300));
    HopTopic.instance.topic(topicCat).send(dataJson);
    await Future.delayed(Duration(milliseconds: 100));
    expect(await completer.future, dataJson);
    HopTopic.instance.closeOpenConnections();
  });

  test('Subscriber Publisher Queue', () async {
    Completer<Map> completer1 = Completer<Map>();
    Completer<Map> completer2 = Completer<Map>();
    HopTopic.instance
        .queue(queueName)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      completer1.complete(msg);
    });
    HopTopic.instance
        .queue(queueName)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      completer2.complete(msg);
    });
    await Future.delayed(Duration(milliseconds: 300));
    HopTopic.instance.queue(queueName).send(dataJson);
    HopTopic.instance.queue(queueName).send(dataJson);
    await Future.delayed(Duration(milliseconds: 100));
    expect(await completer1.future, dataJson);
    expect(await completer2.future, dataJson);
    HopTopic.instance.closeOpenConnections();
  });

  test('Subscriber Publisher Broadcast', () async {
    Completer<Map> completer1 = Completer<Map>();
    Completer<Map> completer2 = Completer<Map>();
    HopTopic.instance
        .exchange(broadcastExchange)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      completer1.complete(msg);
    });
    HopTopic.instance
        .exchange(broadcastExchange)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      completer2.complete(msg);
    });
    await Future.delayed(Duration(milliseconds: 300));
    HopTopic.instance.exchange(broadcastExchange).send(dataJson);
    await Future.delayed(Duration(milliseconds: 100));
    expect(await completer1.future, dataJson);
    expect(await completer2.future, dataJson);
    HopTopic.instance.closeOpenConnections();
  });

  test('Subscriber Publisher Topic Over Exchange', () async {
    Completer<Map> completer = Completer<Map>();
    HopTopic.instance
        .exchange(topicExchange)
        .topic(topicCat)
        .subscribe(outputType: OutputType.JSON)
        .listen((msg) {
      completer.complete(msg);
    });
    await Future.delayed(Duration(milliseconds: 300));
    HopTopic.instance.exchange(topicExchange).topic(topicCat).send(dataJson);
    await Future.delayed(Duration(milliseconds: 100));
    expect(await completer.future, dataJson);
    HopTopic.instance.closeOpenConnections();
  });
}
