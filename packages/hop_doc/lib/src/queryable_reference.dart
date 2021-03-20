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
      "query": {
        "bool": {
          "must": [],
          "filter": [],
        }
      },
      "sort": [],
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

  Query start({int at, Document after, bool nanoDate}) => Query(
        client,
        index,
        compoundBody,
        "",
        at: at,
        after: after,
        nanoDate: nanoDate,
      );

  Query limit(int number) => Query(
        client,
        index,
        compoundBody,
        "",
        limit: number,
      );

  Query orderBy({String field, String order = "asc", bool addId: true}) =>
      Query(
        client,
        index,
        compoundBody,
        field,
        orderBy: order,
        addId: addId,
      );

  Future<IndexSnapshot> get({int size}) async {
    try {
      Map data = compoundBody;
      if (size != null) data["size"] = size;
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

  bool docInQuery(Map<String, dynamic> doc) {
    for (Map query in compoundBody["query"]["bool"]["must"]) {
      if (query.containsKey("match")) {
        final match = query["match"] as Map;
        final key = match.keys.first;
        final value = match.values.first;

        dynamic source = (doc["_source"] as Map);
        for (String token in key.split(".")) {
          if (source.containsKey(token)) {
            source = source[token];
          } else {
            return false;
          }
        }
        if (source != value) return false;
      } else if (query.containsKey("range")) {
        // TODO
      }
    }
    return true;
  }

  Stream<IndexSnapshot> stream() {
    WebSocket ws;
    client.connect("/ws/_changes/$index/*").then((WebSocket websocket) {
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
      IndexSnapshot snapshot = await get();
      _cachedIndex = {};
      if (snapshot.success) {
        for (Document doc in snapshot.docs) {
          if (docInQuery(doc.json)) {
            _cachedIndex[doc.id] = doc;
          }
        }
      }
      controller.add(cachedToIndexSnapshot);
    }

    controller = StreamController<IndexSnapshot>(
        onListen: onListen,
        onResume: () async => controller.add(cachedToIndexSnapshot),
        onCancel: () => ws.close());

    return controller.stream;
  }
}
