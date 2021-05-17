import 'dart:async';
import 'package:flutter/material.dart';
import 'doc.dart';

class DocumentReference {
  HopDocClient client;
  String _index;
  String _id;
  DocumentReference(this.client, this._index, this._id);

  Future<DocumentSnapshot> get() async {
    try {
      final response = await client.get("/$_index/_doc/$_id");
      return DocumentSnapshot(Document.fromJson(response), success: true);
    } catch (e) {
      return DocumentSnapshot(null, success: false, reason: e.toString());
    }
  }

  Widget getWidget({
    required Widget Function(Document?) onData,
    required Widget Function(String) onError,
    required Widget Function() onLoading,
  }) {
    return FutureBuilder<DocumentSnapshot>(
        future: get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.success) {
              return onData(snapshot.data!.doc);
            } else {
              return onError(snapshot.data!.reason!);
            }
          }
          return onLoading();
        });
  }

  Future<DocumentSnapshot> setData(Map<String, dynamic> doc) async {
    try {
      final response = await client.post("/$_index/_doc/$_id", data: doc);
      final document = Document(doc,
          index: _index, id: response["_id"], version: response["_version"]);
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
      final response = await client.delete("/$_index/_doc/$_id");
      final document = Document(null,
          index: _index, id: response["_id"], version: response["_version"]);
      return DocumentSnapshot(document, success: true);
    } catch (e) {
      return DocumentSnapshot(null, success: false, reason: e.toString());
    }
  }
}

class DocumentSnapshot {
  Document? doc;
  bool success;
  String? reason;
  DocumentSnapshot(this.doc, {required this.success, this.reason = ""});
}

class Document {
  Map<String, dynamic>? source;
  String index;
  String id;
  int version;
  List? sort;
  Document(this.source, {required this.index, required this.id, required this.version, this.sort});

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
