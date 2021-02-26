import 'queue.dart';
import 'client.dart';

class HopTopicExchange {
  final HopTopicClient _client;
  final String name;
  final bool create, autoDelete;
  final ExchangeType type;
  HopTopicExchange(
    this._client,
    this.name, {
    this.create = true,
    this.type = ExchangeType.TOPIC,
    this.autoDelete = true,
  });

  Stream<dynamic> listen({OutputType outputType = OutputType.STRING}) {
    HopTopicQueue queue =
        HopTopicQueue(_client, exchange: name, exchangeType: type);
    return queue.listen(outputType: outputType);
  }

  void send(dynamic body) =>
      _client.send(body, name, exchangeType: ExchangeType.FANOUT);

  HopTopicQueue topic(String name) =>
      HopTopicQueue(_client, exchange: this.name, binding: name);

  HopTopicQueue queue(String name) => HopTopicQueue(_client,
      exchange: this.name, exchangeType: type, binding: name, name: name);
}
