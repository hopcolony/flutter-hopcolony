import 'dart:async';

import 'client.dart';
import 'package:hop_topic/lib/dart_amqp.dart' as amqp;

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

  Future<Function> onListen(
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
        controller?.add(HopTopicMessage.fromAMQP(message, outputType)));

    return () {
      channel.close();
    };
  }

  Future<void> send(
    dynamic body,
    String exchangeName, {
    String binding = "",
    String queueName = "",
    ExchangeType exchangeType = ExchangeType.TOPIC,
    bool exchangeIsDurable = true,
  }) async {
    amqp.Channel channel = await _amqpClient.channel();
    if (exchangeName.isEmpty) {
      amqp.Queue queue = await channel.queue(binding, autoDelete: true);
      queue.publish(body);
    } else {
      amqp.Exchange exchange = await channel.exchange(
          exchangeName, parseAMQPExchangeType(exchangeType),
          durable: exchangeIsDurable);
      exchange.publish(body, binding);
    }
    channel.close();
  }

  void close() {
    _amqpClient.close();
  }
}
