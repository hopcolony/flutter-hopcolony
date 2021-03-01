import 'queue.dart';
import 'client.dart';

class HopTopicExchange {
  final HopTopicClient _client;
  final String name;
  final bool create, durable, autoDelete;
  final ExchangeType type;
  HopTopicExchange(
    this._client,
    this.name, {
    this.create = true,
    this.type = ExchangeType.TOPIC,
    this.durable = false,
    this.autoDelete = false,
  });

  Stream<dynamic> subscribe({OutputType outputType = OutputType.STRING}) {
    return HopTopicQueue(
      _client,
      exchange: "amq.fanout",
      exchangeType: ExchangeType.FANOUT,
      exchangeIsDurable: durable,
    ).subscribe(outputType: outputType);
  }

  void send(dynamic body) => _client.send(body, "amq.fanout", exchangeType: ExchangeType.FANOUT);

  HopTopicQueue topic(String name) => HopTopicQueue(
        _client,
        exchange: this.name,
        binding: name,
        exchangeIsDurable: durable,
      );

  HopTopicQueue queue(String name) => HopTopicQueue(
        _client,
        exchange: this.name,
        exchangeType: type,
        binding: name,
        name: name,
        exchangeIsDurable: durable,
      );
}
