import 'dart:async';
import 'client.dart';

class HopTopicPublisher {
  final HopTopicConnectionSettings connectionSettings;
  final String topic;
  HopTopicClient _client;
  final Completer connected = Completer();
  HopTopicPublisher(this.connectionSettings, this.topic) {
    _client = HopTopicClient(settings: connectionSettings);
    _client.getReadyToPublish(topic);
  }

  Future<void> send(dynamic body, {String routingKey}) async {
    await _client.send(body, routingKey: routingKey);
  }

  void close() {
    _client.close();
  }
}
