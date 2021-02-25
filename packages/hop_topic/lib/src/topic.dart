import 'package:dart_amqp/dart_amqp.dart';
import 'package:hop_init/hop_init.dart' as init;
import 'subscriber.dart';
import 'publisher.dart';

class HopTopic {
  init.Project project;
  ConnectionSettings connectionSettings;
  Authenticator authenticator;
  final _host = "topics.hopcolony.io";
  final _port = 32012;
  static final HopTopic instance = HopTopic._internal();
  factory HopTopic() => instance;
  HopTopic._internal() {
    project = init.project;
    authenticator = PlainAuthenticator(init.config.identity, init.config.token);
    connectionSettings = ConnectionSettings(
        host: _host,
        port: _port,
        virtualHost: init.config.identity,
        authProvider: authenticator);
  }

  String get host => _host;
  String get identity => init.config.identity;

  HopTopicSubscriber subscribe(String topic, {OutputType outputType}) =>
      HopTopicSubscriber(connectionSettings, topic, outputType);

  HopTopicPublisher publisher(String topic) =>
      HopTopicPublisher(connectionSettings, topic);
}
