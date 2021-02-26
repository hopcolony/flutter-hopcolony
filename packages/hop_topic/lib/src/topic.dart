import 'package:hop_init/hop_init.dart' as init;
import 'client.dart';
import 'queue.dart';
import 'exchange.dart';

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
      _client = HopTopicClient(settings: connectionSettings);
    }
  }

  String get host => _host;
  String get identity => init.config.identity;

  HopTopicQueue queue(String name) =>
      HopTopicQueue(_client, binding: name, name: name);

  HopTopicExchange exchange(String name,
          {create = true, type = ExchangeType.TOPIC}) =>
      HopTopicExchange(_client, name, create: create, type: type);

  HopTopicQueue topic(String name) =>
      HopTopicQueue(_client, exchange: "amq.topic", binding: name);

  void close() {
    _client.close();
  }
}
