import 'dart:async';
import 'client.dart';

enum OutputType { BYTES, STRING, JSON }

class HopTopicSubscriber {
  final String topic;
  final OutputType outputType;
  final HopTopicConnectionSettings connectionSettings;
  HopTopicClient _client;
  StreamController<dynamic> _controller;
  Stream<dynamic> get stream => _controller.stream;
  HopTopicSubscriber(this.connectionSettings, this.topic, this.outputType) {
    _client = HopTopicClient(settings: connectionSettings);
    _controller =
        StreamController<dynamic>(onListen: start, onCancel: _client.close);
  }

  Future<void> start() async {
    _client.consume(topic).listen((HopTopicMessage message) {
      switch (outputType) {
        case OutputType.BYTES:
          _controller.add(message.payload);
          break;
        case OutputType.STRING:
          _controller.add(message.payloadAsString);
          break;
        case OutputType.JSON:
          {
            if (message.payloadAsJson != null)
              _controller.add(message.payloadAsJson);
            else
              print("Not able to parse receiving message as json");
          }
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
