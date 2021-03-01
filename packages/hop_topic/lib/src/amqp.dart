import 'dart:async';

import 'client.dart';
import 'package:dart_amqp/dart_amqp.dart' as amqp;

class AMQPHopTopicClient extends HopTopicClient {
  amqp.Client _amqpClient;
  AMQPHopTopicClient(amqp.ConnectionSettings settings) {
    _amqpClient = amqp.Client(settings: settings);
  }

  dynamic parseAMQPExchangeType(ExchangeType type) {
    switch (type) {
      case ExchangeType.DIRECT:
        return amqp.ExchangeType.DIRECT;
      case ExchangeType.FANOUT:
        return amqp.ExchangeType.FANOUT;
      case ExchangeType.TOPIC:
        return amqp.ExchangeType.TOPIC;
      default:
        break;
    }
  }

  Map<StreamController<dynamic>, amqp.Consumer> _subscriptions = {};

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
    amqp.Channel channel = await _amqpClient.channel();

    amqp.Queue queue = await channel.queue(queueName,
        exclusive: queueIsExclusive, autoDelete: queueAutoDelete);

    if (exchangeName.isNotEmpty) {
      amqp.Exchange exchange = await channel.exchange(
          exchangeName, parseAMQPExchangeType(exchangeType),
          durable: exchangeIsDurable);
      queue = await queue.bind(exchange, binding);
    }

    amqp.Consumer consumer = await queue.consume();
    consumer.listen((amqp.AmqpMessage message) =>
        controller.add(HopTopicMessage.fromAMQP(message, outputType)));

     _subscriptions[controller] = null;
  }

  Future<void> send(
    dynamic body,
    String exchangeName, {
    String binding = "",
    String queueName = "",
    ExchangeType exchangeType = ExchangeType.TOPIC,
    bool exchangeIsDurable = false,
  }) async {
    amqp.Channel channel = await _amqpClient.channel();
    amqp.Exchange exchange = await channel.exchange(
        exchangeName, parseAMQPExchangeType(exchangeType),
        durable: exchangeIsDurable);
    exchange.publish(body, binding);
  }

  void close(StreamController<dynamic> controller) {
    final consumer = _subscriptions[controller];
    if(consumer != null) consumer.cancel();
  }
}
