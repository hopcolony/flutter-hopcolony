import 'package:hop_init/hop_init.dart' as init;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hop_topic/src/amqp.dart';
import 'client.dart';
import 'queue.dart';
import 'exchange.dart';
import 'stomp.dart';

class HopTopic {
  init.Project project;
  HopTopicConnectionSettings connectionSettings;
  HopTopicAuthenticator authenticator;
  HopTopicClient _client;
  final _host = "topics.hopcolony.io";
  static final HopTopic instance = HopTopic._internal();
  factory HopTopic() => instance;
  HopTopic._internal() {
    project = init.project;
    authenticator = HopTopicAuthenticator(
        username: init.config.identity, password: init.config.token);
    connectionSettings = HopTopicConnectionSettings(
        host: _host,
        virtualHost: init.config.identity,
        authenticator: authenticator);

    if (_client == null) {
      _client = kIsWeb ? STOMPHopTopicClient(connectionSettings) : AMQPHopTopicClient(connectionSettings.toAMQP);
    }
  }

  String get host => _host;
  String get identity => init.config.identity;

  HopTopicQueue queue(String name) =>
      HopTopicQueue(_client, binding: name, name: name);

  HopTopicExchange exchange(String name,
          {create = false, type = ExchangeType.TOPIC}) =>
      HopTopicExchange(_client, name, create: create, type: type);

  HopTopicQueue topic(String name) =>
      HopTopicQueue(_client, exchange: "amq.topic", binding: name);
}

