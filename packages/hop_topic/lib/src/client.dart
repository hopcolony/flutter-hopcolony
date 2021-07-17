import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:hop_topic/lib/dart_amqp.dart' as amqp;
import 'package:stomp_dart_client/stomp_frame.dart';

enum ExchangeType { DIRECT, FANOUT, TOPIC }
enum OutputType { BYTES, STRING, JSON }

class HopTopicMessage {
  final Uint8List? payload;
  final String? payloadAsString;
  final Map<String, dynamic>? payloadAsJson;
  HopTopicMessage(this.payload, this.payloadAsString, this.payloadAsJson);

  static dynamic fromAMQP(amqp.AmqpMessage message, OutputType outputType) {
    final msg = HopTopicMessage(
        message.payload,
        message.payloadAsString,
        outputType == OutputType.JSON
            ? Map<String, dynamic>.from(message.payloadAsJson!)
            : null);
    return HopTopicMessage.fromHopTopicMessage(msg, outputType);
  }

  static dynamic fromSTOMP(StompFrame message, OutputType outputType) {
    dynamic json;
    try {
      json = jsonDecode(message.body!);
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
      this.virtualHost = "/",
      required this.authenticator});

  amqp.ConnectionSettings get toAMQP => amqp.ConnectionSettings(
      host: host,
      port: amqpPort,
      virtualHost: virtualHost,
      authProvider: authenticator.toAMQP);
}

class OpenConnection {
  final String queue, exchange;
  StreamController<dynamic>? controller;
  Function? unsubscribeFunction;
  OpenConnection(this.queue, this.exchange);

  void close() {
    controller?.close();
    if (unsubscribeFunction != null) unsubscribeFunction!();
  }

  String toString() =>
      "Opened connection with queue ($queue) and exchange ($exchange)";
}

abstract class HopTopicClient {
  Future<Function> onListen(
    StreamController<dynamic> controller,
    String exchangeName,
    ExchangeType exchangeType,
    bool exchangeIsDurable,
    String binding,
    String queueName,
    bool queueIsDurable,
    bool queueIsExclusive,
    bool queueAutoDelete,
    OutputType outputType,
  );

  Stream<dynamic> subscribe(
    Function addOpenConnection,
    String exchangeName,
    ExchangeType exchangeType,
    String binding,
    String queueName,
    bool queueIsDurable,
    bool queueIsExclusive,
    bool queueAutoDelete,
    OutputType outputType,
    bool exchangeIsDurable,
  ) {
    OpenConnection openConnection = OpenConnection(queueName, exchangeName);
    late StreamController<dynamic> controller;
    controller = StreamController<dynamic>(
      onListen: () async {
        Function unsubscribeFunction = await onListen(
            controller,
            exchangeName,
            exchangeType,
            exchangeIsDurable,
            binding,
            queueName,
            queueIsDurable,
            queueIsExclusive,
            queueAutoDelete,
            outputType);
        openConnection.unsubscribeFunction = unsubscribeFunction;
      },
      onCancel: openConnection.close,
    );
    openConnection.controller = controller;
    addOpenConnection(openConnection);
    return controller.stream;
  }

  Future<void> send(
    dynamic body,
    String exchangeName, {
    String binding = "",
    String queueName = "",
    ExchangeType exchangeType = ExchangeType.TOPIC,
    bool exchangeIsDurable = true,
  });

  void close();
}
