import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hop_doc/src/geo.dart';
import 'doc.dart';
import 'document_reference.dart';
import 'index_reference.dart';
import 'query.dart';
import 'dart:convert';

class QueryableReference {
  HopDocClient client;
  String index;
  QueryableReference(this.client, this.index);

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

  Query where(
    String field, {
    String? isEqualTo,
    int? isGreaterThan,
    int? isGreaterThanOrEqualTo,
    int? isLessThan,
    int? isLessThanOrEqualTo,
    String? contains,
  }) =>
      Query(client, index, compoundBody, field,
          isEqualTo: isEqualTo,
          isGreaterThan: isGreaterThan,
          isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
          isLessThan: isLessThan,
          isLessThanOrEqualTo: isLessThanOrEqualTo,
          contains: contains);

  Query withinRadius({
    required GeoPoint center,
    required String radius,
    required String field,
  }) =>
      Query(
        client,
        index,
        compoundBody,
        field,
        isWithinRadius:
            GeoDistanceQuery(center: center, radius: radius, field: field),
      );

  Query withinBox({
    required GeoPoint topLeft,
    required GeoPoint bottomRight,
    required String field,
  }) =>
      Query(
        client,
        index,
        compoundBody,
        field,
        isWithinBox: GeoBoxQuery(
            topLeft: topLeft, bottomRight: bottomRight, field: field),
      );

  Query start({int? at, Document? after, bool nanoDate: false}) => Query(
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

  Query orderBy(
          {required String field, String order = "asc", bool addId: true}) =>
      Query(
        client,
        index,
        compoundBody,
        field,
        orderBy: order,
        addId: addId,
      );

  Future<IndexSnapshot> get({int? size, bool onlyIds: false}) async {
    try {
      Map<String, dynamic> data = compoundBody;
      if (onlyIds) data["stored_fields"] = [];
      if (size != null) data["size"] = size;
      final response = await client.post("/$index/_search", data: data);
      final docs = (response["hits"]["hits"] as List)
          .map((doc) => Document.fromJson(doc))
          .toList();
      return IndexSnapshot(docs, success: true);
    } catch (e) {
      return IndexSnapshot([], success: false, reason: e.toString());
    }
  }

  Widget getWidget({
    required Widget Function(List<Document>) onData,
    required Widget Function(String) onError,
    required Widget Function() onLoading,
  }) {
    return FutureBuilder<IndexSnapshot>(
        future: get(),
        builder: (context, AsyncSnapshot<IndexSnapshot> snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.success) {
              return onData(snapshot.data!.docs);
            } else {
              return onError(snapshot.data!.reason);
            }
          }
          return onLoading();
        });
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
}
