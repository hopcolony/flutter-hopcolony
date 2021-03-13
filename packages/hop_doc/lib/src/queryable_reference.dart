import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hop_doc/src/geo.dart';
import 'doc.dart';
import 'document_reference.dart';
import 'index_reference.dart';
import 'query.dart';
import 'package:websocket/websocket.dart' show WebSocket;
import 'dart:convert';

class QueryableReference {
  HopDocClient client;
  String index;
  StreamController<IndexSnapshot> controller;
  Map<String, Document> _cachedIndex;
  QueryableReference(this.client, this.index);

  void dispose() {
    controller.close();
  }

  Map<String, dynamic> get compoundBody {
    return {
      "size": 100,
      "from": 0,
      "query": {
        "bool": {
          "must": [],
          "filter": [],
        }
      }
    };
  }

  Query where(String field,
          {String isEqualTo,
          int isGreaterThan,
          int isGreaterThanOrEqualTo,
          int isLessThan,
          int isLessThanOrEqualTo}) =>
      Query(client, index, compoundBody, field,
          isEqualTo: isEqualTo,
          isGreaterThan: isGreaterThan,
          isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
          isLessThan: isLessThan,
          isLessThanOrEqualTo: isLessThanOrEqualTo);

  Query withinRadius({GeoPoint center, String radius, String field}) => Query(
        client,
        index,
        compoundBody,
        field,
        isWithinRadius:
            GeoDistanceQuery(center: center, radius: radius, field: field),
      );

  Query withinBox({GeoPoint topLeft, GeoPoint bottomRight, String field}) =>
      Query(
        client,
        index,
        compoundBody,
        field,
        isWithinBox: GeoBoxQuery(
            topLeft: topLeft, bottomRight: bottomRight, field: field),
      );

  Future<IndexSnapshot> get({int size = 100, int from = 0}) async {
    try {
      Map data = compoundBody;
      data["size"] = size;
      data["from"] = from;
      Response response = await client.post("/$index/_search", data: data);
      final docs = (response.data["hits"]["hits"] as List)
          .map((doc) => Document.fromJson(doc))
          .toList();
      return IndexSnapshot(docs, success: true);
    } catch (e) {
      return IndexSnapshot([], success: false, reason: e.toString());
    }
  }

  IndexSnapshot get cachedToIndexSnapshot {
    return IndexSnapshot(_cachedIndex.values.toList(), success: true);
  }

  bool docInQuery(doc) {
    for (Map query in compoundBody["query"]["bool"]["must"]) {
      if (query.containsKey("match")) {
        final match = query["match"] as Map;
        final key = match.keys.first;
        final value = match.values.first;
        if ((doc["_source"] as Map).containsKey(key) &&
            doc["_source"][key] != value) {
          return false;
        }
      } else if (query.containsKey("range")) {
        // TODO
      }
    }
    return true;
  }

  Stream<IndexSnapshot> stream() {
    WebSocket ws;
    client.connect("/$index/*").then((WebSocket websocket) {
      ws = websocket;
      print('[+]Connected to $index stream');
      if (ws.readyState == 1) {
        ws.stream.listen(
          (data) {
            Map<String, dynamic> doc = jsonDecode(data);
            if (doc["_operation"] == "DELETE") {
              _cachedIndex.remove(doc["_id"]);
            } else if (docInQuery(doc)) {
              _cachedIndex[doc["_id"]] = Document(doc["_source"],
                  index: doc["_index"],
                  id: doc["_id"],
                  version: doc["_version"]);
            }

            controller.add(cachedToIndexSnapshot);
          },
          onDone: () => print('[+]Closed connection to $index stream'),
          onError: (err) =>
              print('[!]Error on $index stream -- ${err.toString()}'),
          cancelOnError: true,
        );
      } else
        print('[!]Connection denied to $index stream');
    });

    void onListen() async {
      IndexSnapshot current = await get();
      controller.add(current);
      _cachedIndex = {for (Document doc in current.docs) doc.id: doc};
    }

    controller = StreamController<IndexSnapshot>(
        onListen: onListen,
        onResume: () async => controller.add(cachedToIndexSnapshot),
        onCancel: () => ws.close());

    return controller.stream;
  }
}
