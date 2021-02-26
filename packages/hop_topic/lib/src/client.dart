import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dart_amqp/dart_amqp.dart' as amqp;
import 'package:stomp_dart_client/stomp.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

enum ExchangeType { DIRECT, FANOUT, TOPIC }
enum OutputType { BYTES, STRING, JSON }

class HopTopicMessage {
  final Uint8List payload;
  final String payloadAsString;
  final Map<String, dynamic> payloadAsJson;
  HopTopicMessage(this.payload, this.payloadAsString, this.payloadAsJson);

  static dynamic fromAMQP(amqp.AmqpMessage message, OutputType outputType) {
    final msg = HopTopicMessage(message.payload, message.payloadAsString,
        outputType == OutputType.JSON ? message.payloadAsJson : null);
    return HopTopicMessage.fromHopTopicMessage(msg, outputType);
  }

  static dynamic fromSTOMP(StompFrame message, OutputType outputType) {
    dynamic json;
    try {
      json = jsonDecode(message.body);
    } catch (e) {}
    final msg = HopTopicMessage(message.binaryBody, message.body, json);
    return HopTopicMessage.fromHopTopicMessage(msg, outputType);
  }

  static dynamic fromHopTopicMessage(
      HopTopicMessage message, OutputType outputType) {
    switch (outputType) {
      case OutputType.BYTES:
        return message.payload;
      case OutputType.STRING:
        return message.payloadAsString;
      case OutputType.JSON:
        {
          if (message.payloadAsJson != null)
            return message.payloadAsJson;
          else
            print("Not able to parse receiving message as json");
          break;
        }
      default:
        break;
    }
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
            onConnect: (client, _) {
              if (!connected.isCompleted) connected.complete();
            }),
      );
    } else {
      _amqpClient = amqp.Client(settings: settings.toAMQP);
    }
  }

  Stream<dynamic> listen(
      String exchange,
      ExchangeType exchangeType,
      String binding,
      String queue,
      bool exclusive,
      bool autoDelete,
      OutputType outputType,
      {bool durable = true}) {
    Function onListen = kIsWeb ? onListenSTOMP : onListenAMQP;
    _controller = StreamController<dynamic>(
      onListen: () => onListen(exchange, exchangeType, binding, queue,
          exclusive, autoDelete, outputType, durable),
      onCancel: close,
    );
    return _controller.stream;
  }

  dynamic parseAMQPExchangeType(ExchangeType type) {
    switch (type) {
      case ExchangeType.DIRECT:
        return amqp.ExchangeType.DIRECT;
      case ExchangeType.FANOUT:
        return amqp.ExchangeType.FANOUT;
      case ExchangeType.TOPIC:
        return amqp.ExchangeType.TOPIC;
      default:
        break;
    }
  }

  String getSTOMPDestination(String exchange, String binding, String queue) {
    String destination;
    if (exchange.isEmpty) {
      if (queue.isNotEmpty) {
        destination = "/queue/$queue";
      } else {
        destination = binding.isEmpty ? "/topic/#" : "/topic/$binding";
      }
    } else {
      destination = binding.isEmpty
          ? "/exchange/$exchange/#"
          : "/exchange/$exchange/$binding";
    }
    return destination;
  }

  void onListenAMQP(
      String exchangeName,
      ExchangeType exchangeType,
      String binding,
      String queueName,
      bool exclusive,
      bool autoDelete,
      OutputType outputType,
      bool durable) async {
    amqp.Channel channel = await _amqpClient.channel();

    amqp.Queue queue = await channel.queue(queueName,
        exclusive: exclusive, autoDelete: autoDelete);

    if (exchangeName.isNotEmpty) {
      amqp.Exchange exchange = await channel.exchange(
          exchangeName, parseAMQPExchangeType(exchangeType),
          durable: durable);
      queue = await queue.bind(exchange, binding);
    }

    amqp.Consumer consumer = await queue.consume();
    consumer.listen((amqp.AmqpMessage message) =>
        _controller.add(HopTopicMessage.fromAMQP(message, outputType)));
  }

  Future<void> onListenSTOMP(
      String exchange,
      ExchangeType exchangeType,
      String binding,
      String queue,
      bool exclusive,
      bool autoDelete,
      OutputType outputType,
      bool durable) async {
    _stompClient.activate();
    await connected.future;
    _stompUnsubscribeFunction = _stompClient.subscribe(
      destination: getSTOMPDestination(exchange, binding, queue),
      headers: queue.isNotEmpty
          ? {
              "x-queue-name": queue,
              "durable": "false",
              "auto-delete": "true",
              "exclusive": "false"
            }
          : {
              "durable": "false",
              "auto-delete": "true",
            },
      callback: (frame) =>
          _controller.add(HopTopicMessage.fromSTOMP(frame, outputType)),
    );
  }

  Future<void> send(dynamic body, String exchangeName,
      {ExchangeType exchangeType = ExchangeType.TOPIC,
      String binding = "#",
      String queue = "",
      durable = true}) async {
    if (kIsWeb) {
      _stompClient.activate();
      await connected.future;
      if (body is Map) body = jsonEncode(body);
      _stompClient.send(
          destination: getSTOMPDestination(exchangeName, binding, queue),
          body: body);
    } else {
      amqp.Channel channel = await _amqpClient.channel();
      amqp.Exchange exchange = await channel.exchange(
          exchangeName, parseAMQPExchangeType(exchangeType),
          durable: durable);
      exchange.publish(body, binding);
    }
  }

  void close() {
    _amqpClient?.close();
    if (_stompUnsubscribeFunction != null) {
      _stompUnsubscribeFunction();
    }
    _stompClient?.deactivate();
    _controller?.close();
  }
}
