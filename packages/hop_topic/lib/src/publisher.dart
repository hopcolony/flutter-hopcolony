import 'dart:async';

import 'package:dart_amqp/dart_amqp.dart';

class HopTopicPublisher {
  final ConnectionSettings connectionSettings;
  final String topic;
  Client _client;
  Exchange _exchange;
  final Completer connected = Completer();
  HopTopicPublisher(this.connectionSettings, this.topic) {
    init();
  }

  Future<void> init() async {
    _client = Client(settings: connectionSettings);
    Channel channel = await _client.channel();
    _exchange = await channel.exchange(topic, ExchangeType.FANOUT);
    connected.complete();
  }

  Future<void> send(dynamic body, {String routingKey}) async {
    await connected.future;
    _exchange?.publish(body, routingKey);
  }

  void close() {
    _client?.close();
  }
}
