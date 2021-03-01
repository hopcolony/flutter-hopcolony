import 'queue.dart';
import 'client.dart';

class HopTopicExchange {
  final Function addOpenConnection;
  final HopTopicClient _client;
  final String name;
  final bool create, durable, autoDelete;
  final ExchangeType type;
  HopTopicExchange(
    this.addOpenConnection,
    this._client,
    this.name, {
    this.create = true,
    this.type = ExchangeType.TOPIC,
    this.durable = true,
    this.autoDelete = false,
  });

  Stream<dynamic> subscribe({OutputType outputType = OutputType.STRING}) {
    return HopTopicQueue(
      addOpenConnection,
      _client,
      exchange: name,
      exchangeType: ExchangeType.FANOUT,
      exchangeIsDurable: durable,
    ).subscribe(outputType: outputType);
  }

  void send(dynamic body) =>
      _client.send(body, name, exchangeType: ExchangeType.FANOUT);

  HopTopicQueue topic(String name) => HopTopicQueue(
        addOpenConnection,
        _client,
        exchange: this.name,
        binding: name,
        exchangeIsDurable: durable,
      );

  HopTopicQueue queue(String name) => HopTopicQueue(
        addOpenConnection,
        _client,
        exchange: this.name,
        exchangeType: type,
        binding: name,
        name: name,
        exchangeIsDurable: durable,
      );
}
