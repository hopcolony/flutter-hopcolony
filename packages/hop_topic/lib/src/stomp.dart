import 'dart:async';
import 'dart:convert';

import 'package:stomp_dart_client/stomp_config.dart';

import 'client.dart';
import 'package:stomp_dart_client/stomp.dart';

class STOMPHopTopicClient extends HopTopicClient {
  StompClient _stompClient;
  dynamic _stompUnsubscribeFunction;

  Completer connected = Completer();
  STOMPHopTopicClient(HopTopicConnectionSettings settings) {
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

  Map<StreamController<dynamic>, Function> _subscriptions = {};

  Future<void> onListen(
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
  ) async {
    _stompClient.activate();
    await connected.future;

    Map<String, String> headers = {
      "durable": queueIsDurable.toString(),
      "auto-delete": queueAutoDelete.toString(),
      "exclusive": queueIsExclusive.toString(),
    };
    if (queueName.isNotEmpty) headers["x-queue-name"] = queueName;

    _stompUnsubscribeFunction = _stompClient.subscribe(
      destination: getSTOMPDestination(exchangeName, binding, queueName),
      headers: headers,
      callback: (frame) =>
          controller.add(HopTopicMessage.fromSTOMP(frame, outputType)),
    );

    _subscriptions[controller] = _stompUnsubscribeFunction;
  }

  Future<void> send(
    dynamic body,
    String exchangeName, {
    String binding = "",
    String queueName = "",
    ExchangeType exchangeType = ExchangeType.TOPIC,
    bool exchangeIsDurable = false,
  }) async {
    _stompClient.activate();
    await connected.future;
    print(getSTOMPDestination(exchangeName, binding, queueName));
    if (body is Map) body = jsonEncode(body);
    _stompClient.send(
      destination: getSTOMPDestination(exchangeName, binding, queueName),
      body: body,
    );
  }

  void close(StreamController<dynamic> controller) {
    final unsubscribeFn = _subscriptions[controller];
    if(unsubscribeFn != null) unsubscribeFn();
  }
}
