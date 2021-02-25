import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dart_amqp/dart_amqp.dart' as amqp;
import 'package:stomp_dart_client/stomp.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class HopTopicMessage {
  final Uint8List payload;
  final String payloadAsString;
  final Map<String, dynamic> payloadAsJson;
  HopTopicMessage(this.payload, this.payloadAsString, this.payloadAsJson);

  factory HopTopicMessage.fromAMQP(amqp.AmqpMessage message) => HopTopicMessage(
      message.payload, message.payloadAsString, message.payloadAsJson);

  factory HopTopicMessage.fromSTOMP(StompFrame message) {
    dynamic json;
    try {
      json = jsonDecode(message.body);
    } catch (e) {}
    return HopTopicMessage(message.binaryBody, message.body, json);
  }
}

class HopTopicAuthenticator {
  final String username;
  final String password;
  HopTopicAuthenticator({this.username = "guest", this.password = "guest"});

  amqp.Authenticator get toAMQP => amqp.PlainAuthenticator(username, password);
}

class HopTopicConnectionSettings {
  final String host, virtualHost;
  final int amqpPort, stompPort;
  final HopTopicAuthenticator authenticator;
  HopTopicConnectionSettings(
      {this.host = "topics.hopcolony.io",
      this.amqpPort = 32012,
      this.stompPort = 443,
      this.virtualHost,
      this.authenticator});

  amqp.ConnectionSettings get toAMQP => amqp.ConnectionSettings(
      host: host,
      port: amqpPort,
      virtualHost: virtualHost,
      authProvider: authenticator.toAMQP);
}

class HopTopicClient {
  final HopTopicConnectionSettings settings;
  Completer connected = Completer();
  String _publishTopic;

  // AMQP
  amqp.Client _amqpClient;
  amqp.Exchange _amqpExchange;

  // STOMP
  StompClient _stompClient;
  dynamic _stompUnsubscribeFunction;

  // Stream
  StreamController<dynamic> _controller;
  Stream<HopTopicMessage> get stream => _controller.stream;

  HopTopicClient({this.settings}) {
    if (kIsWeb) {
      _stompClient = StompClient(
        config: StompConfig(
            url: 'wss://${settings.host}:${settings.stompPort}/ws',
            stompConnectHeaders: {
              'login': settings.authenticator.username,
              'passcode': settings.authenticator.password,
              'host': settings.virtualHost
            },
            onConnect: (client, _) => connected.complete()),
      );
    } else {
      _amqpClient = amqp.Client(settings: settings.toAMQP);
    }
  }

  Stream<HopTopicMessage> consume(String topic) {
    if (kIsWeb) {
      _controller = StreamController<HopTopicMessage>(
          onListen: () => onListenSTOMP(topic), onCancel: close);
    } else {
      _controller = StreamController<HopTopicMessage>(
          onListen: () => onListenAMQP(topic), onCancel: close);
    }
    return _controller.stream;
  }

  void onListenAMQP(String topic) {
    _amqpClient
        .channel()
        .then((amqp.Channel channel) =>
            channel.exchange(topic, amqp.ExchangeType.FANOUT))
        .then((amqp.Exchange exchange) => exchange.bindPrivateQueueConsumer([]))
        .then((amqp.Consumer consumer) => consumer.listen(
            (amqp.AmqpMessage message) =>
                _controller.add(HopTopicMessage.fromAMQP(message))));
  }

  Future<void> onListenSTOMP(String topic) async {
    _stompClient.activate();
    await connected.future;
    _stompUnsubscribeFunction = _stompClient.subscribe(
      destination: "/exchange/$topic",
      callback: (frame) => _controller.add(HopTopicMessage.fromSTOMP(frame)),
    );
  }

  Future<void> getReadyToPublish(String topic) async {
    _publishTopic = topic;
    if (kIsWeb) {
      _stompClient.activate();
    } else {
      amqp.Channel channel = await _amqpClient.channel();
      _amqpExchange = await channel.exchange(topic, amqp.ExchangeType.FANOUT);
      connected.complete();
    }
  }

  Future<void> send(dynamic body, {String routingKey}) async {
    await connected.future;
    if (kIsWeb) {
      if (body is Map) body = jsonEncode(body);
      _stompClient.send(destination: "/exchange/$_publishTopic", body: body);
    } else {
      _amqpExchange?.publish(body, routingKey);
    }
  }

  void close() {
    _amqpClient?.close();
    if (_stompUnsubscribeFunction != null) {
      _stompUnsubscribeFunction(unsubscribeHeaders: {});
    }
    _stompClient?.deactivate();
    _controller?.close();
  }
}
