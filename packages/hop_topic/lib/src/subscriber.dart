import 'dart:async';

import 'package:dart_amqp/dart_amqp.dart';

enum OutputType { BYTES, STRING, JSON }

class HopTopicSubscriber {
  final String topic;
  final OutputType outputType;
  final ConnectionSettings connectionSettings;
  Client _client;
  StreamController<dynamic> _controller;
  Stream<dynamic> get stream => _controller.stream;

  HopTopicSubscriber(this.connectionSettings, this.topic, this.outputType) {
    _controller = StreamController<dynamic>(
        onListen: start, onCancel: () => _client.close());
  }

  Future<void> start() async {
    _client = Client(settings: connectionSettings);
    Channel channel = await _client.channel();
    Exchange exchange = await channel.exchange(topic, ExchangeType.FANOUT);
    Consumer consumer = await exchange.bindPrivateQueueConsumer([]);
    consumer.listen((AmqpMessage message) {
      switch (outputType) {
        case OutputType.BYTES:
          _controller.add(message.payload);
          break;
        case OutputType.STRING:
          _controller.add(message.payloadAsString);
          break;
        case OutputType.JSON:
          _controller.add(message.payloadAsJson);
          break;
        default:
          break;
      }
    });
  }

  void close() {
    _client?.close();
    _controller.close();
  }
}
