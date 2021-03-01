import 'dart:async';
import 'client.dart';

class HopTopicQueue {
  final Function addOpenConnection;
  final HopTopicClient _client;
  final String exchange, binding, name;
  final ExchangeType exchangeType;
  final bool durable, exclusive, autoDelete, exchangeIsDurable;
  HopTopicQueue(
    this.addOpenConnection,
    this._client, {
    this.exchange = "",
    this.exchangeType = ExchangeType.TOPIC,
    this.exchangeIsDurable = true,
    this.binding = "",
    this.name = "",
    this.durable = false,
    this.exclusive = false,
    this.autoDelete = true,
  });

  Stream<dynamic> subscribe({OutputType outputType = OutputType.STRING}) {
    return _client.subscribe(addOpenConnection, exchange, exchangeType, binding,
        name, durable, exclusive, autoDelete, outputType, exchangeIsDurable);
  }

  void send(dynamic body) => _client.send(body, exchange,
      exchangeType: exchangeType,
      binding: binding,
      queueName: name,
      exchangeIsDurable: exchangeIsDurable);
}
