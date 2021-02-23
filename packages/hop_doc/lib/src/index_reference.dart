import 'package:dio/dio.dart';
import 'queryable_reference.dart';
import 'document_reference.dart';
import 'doc.dart';

class IndexReference extends QueryableReference {
  IndexReference(HopDocClient client, String index) : super(client, index);

  Future<DocumentSnapshot> add(Map<String, dynamic> doc) async {
    try {
      Response response = await client.post("/$index/_doc", data: doc);
      final document = Document(doc,
          index: index,
          id: response.data["_id"],
          version: response.data["_version"]);
      return DocumentSnapshot(document, success: true);
    } catch (e) {
      return DocumentSnapshot(null, success: false, reason: e.toString());
    }
  }

  DocumentReference document(String id) => DocumentReference(client, index, id);

  Future<int> get count async {
    try {
      Response response = await client.get("/$index/_count");
      return response.data["count"];
    } catch (e) {
      return 0;
    }
  }

  Future<bool> delete() async {
    try {
      await client.delete("/$index");
      return true;
    } catch (e) {
      return true;
    }
  }
}

class IndexSnapshot {
  List<Document> docs;
  bool success;
  String reason;
  IndexSnapshot(this.docs, {this.success, this.reason = ""});
}

class Index {
  Map<String, dynamic> source;
  String name, status;
  int numDocs, numShards, numReplicas, activePrimaryShards, activeShards;
  Index({
    this.name,
    this.numDocs,
    this.status,
    this.numShards,
    this.numReplicas,
    this.activePrimaryShards,
    this.activeShards,
  });

  Index.fromJson(String name, Map<String, dynamic> json, int numDocs)
      : name = name,
        numDocs = numDocs,
        status = json["status"],
        numShards = json["number_of_shards"],
        numReplicas = json["number_of_replicas"],
        activePrimaryShards = json["active_primary_shards"],
        activeShards = json["active_shards"];
}