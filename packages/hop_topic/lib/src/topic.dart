import 'package:hop_init/hop_init.dart' as init;
import 'client.dart';
import 'subscriber.dart';
import 'publisher.dart';

class HopTopic {
  init.Project project;
  HopTopicConnectionSettings connectionSettings;
  HopTopicAuthenticator authenticator;
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
  }

  String get host => _host;
  String get identity => init.config.identity;

  HopTopicSubscriber subscribe(String topic, {OutputType outputType}) =>
      HopTopicSubscriber(connectionSettings, topic, outputType);

  HopTopicPublisher publisher(String topic) =>
      HopTopicPublisher(connectionSettings, topic);
}
