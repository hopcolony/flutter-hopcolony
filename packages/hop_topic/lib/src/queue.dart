import 'dart:async';
import 'client.dart';

class HopTopicQueue {
  final HopTopicClient _client;
  final String exchange, binding, name;
  final ExchangeType exchangeType;
  final bool exclusive, autoDelete, durable;
  HopTopicQueue(
    this._client, {
    this.exchange = "",
    this.binding = "#",
    this.name = "",
    this.exchangeType = ExchangeType.TOPIC,
    this.exclusive = false,
    this.autoDelete = true,
    this.durable = true,
  });

  Stream<dynamic> listen({OutputType outputType = OutputType.STRING}) =>
      _client.listen(exchange, exchangeType, binding, name, exclusive,
          autoDelete, outputType,
          durable: durable);

  void send(dynamic body) => _client.send(body, exchange,
      exchangeType: exchangeType,
      binding: binding,
      queue: name,
      durable: durable);

  void close() => _client.close();
}
