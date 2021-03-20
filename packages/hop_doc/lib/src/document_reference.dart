import 'dart:async';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:websocket/websocket.dart' show WebSocket;

import 'doc.dart';

class DocumentReference {
  HopDocClient client;
  String _index;
  String _id;
  StreamController<DocumentSnapshot> controller;
  DocumentSnapshot _cachedDocument;
  DocumentReference(this.client, this._index, this._id);

  Future<DocumentSnapshot> get() async {
    try {
      Response response = await client.get("/$_index/_doc/$_id");
      return DocumentSnapshot(Document.fromJson(response.data), success: true);
    } catch (e) {
      return DocumentSnapshot(null, success: false, reason: e.toString());
    }
  }

  Future<DocumentSnapshot> setData(Map<String, dynamic> doc) async {
    try {
      Response response = await client.post("/$_index/_doc/$_id", data: doc);
      final document = Document(doc,
          index: _index,
          id: response.data["_id"],
          version: response.data["_version"]);
      return DocumentSnapshot(document, success: true);
    } catch (e) {
      return DocumentSnapshot(null, success: false, reason: e.toString());
    }
  }

  Future<DocumentSnapshot> update(Map<String, dynamic> fields) async {
    try {
      await client.post("/$_index/_doc/$_id/_update", data: {"doc": fields});
      return await get();
    } catch (e) {
      return DocumentSnapshot(null, success: false, reason: e.toString());
    }
  }

  Future<DocumentSnapshot> delete() async {
    try {
      Response response = await client.delete("/$_index/_doc/$_id");
      final document = Document(null,
          index: _index,
          id: response.data["_id"],
          version: response.data["_version"]);
      return DocumentSnapshot(document, success: true);
    } catch (e) {
      return DocumentSnapshot(null, success: false, reason: e.toString());
    }
  }

  Stream<DocumentSnapshot> stream() {
    WebSocket ws;
    client.connect("/ws/_changes/$_index/$_id").then((WebSocket websocket) {
      ws = websocket;
      print('[+]Connected to $_index/$_id stream');
      if (ws.readyState == 1) {
        ws.stream.listen(
          (data) {
            Map<String, dynamic> doc = jsonDecode(data);
            if (_cachedDocument.doc == null) {
              _cachedDocument.success = true;
              _cachedDocument.doc = Document.fromJson(doc);
            } else {
              _cachedDocument.doc.version = doc["_version"];
              _cachedDocument.doc.source = doc["_source"];
            }

            controller.add(_cachedDocument);
          },
          onDone: () => print('[+]Closed connection to $_index/$_id stream'),
          onError: (err) =>
              print('[!]Error on $_index/$_id stream -- ${err.toString()}'),
          cancelOnError: true,
        );
      } else
        print('[!]Connection denied to $_index/$_id stream');
    });

    void onListen() async {
      _cachedDocument = await get();
      controller.add(_cachedDocument);
    }

    controller = StreamController<DocumentSnapshot>(
        onListen: onListen,
        onResume: () => controller.add(_cachedDocument),
        onCancel: () => ws.close());

    return controller.stream;
  }
}

class DocumentSnapshot {
  Document doc;
  bool success;
  String reason;
  DocumentSnapshot(this.doc, {this.success, this.reason = ""});
}

class Document {
  Map<String, dynamic> source;
  String index;
  String id;
  int version;
  List sort;
  Document(this.source, {this.index, this.id, this.version, this.sort});
  
  Document.fromJson(Map<String, dynamic> json)
      : source = json["_source"],
        index = json["_index"],
        id = json["_id"],
        version = json["_version"],
        sort = json["sort"];

  Map<String, dynamic> get json => {
        "_source": source,
        "_id": id,
        "_index": index,
        "_version": version,
      };
}
