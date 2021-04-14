import 'package:hop_doc/hop_doc.dart';
import 'package:hop_doc/src/geo.dart';
import 'package:hop_doc/src/utils.dart';
import 'doc.dart';
import 'queryable_reference.dart';

enum QueryType {
  IS_EQUAL_TO,
  IS_GREATER_THAN,
  IS_GREATER_THAN_OR_EQUAL_TO,
  IS_LESS_THAN,
  IS_LESS_THAN_OR_EQUAL_TO,
  CONTAINS,
  IS_WITHIN_RADIUS,
  IS_WITHIN_BOX,
  START_AT,
  START_AFTER,
  LIMIT,
  ORDER_BY
}

class GeoDistanceQuery {
  final GeoPoint center;
  final String radius, field;
  GeoDistanceQuery({this.center, this.radius, this.field});
}

class GeoBoxQuery {
  final GeoPoint topLeft, bottomRight;
  final String field;
  GeoBoxQuery({this.topLeft, this.bottomRight, this.field});
}

class Query extends QueryableReference {
  Map<String, dynamic> _compoundQuery;
  String _field;
  QueryType _queryType;
  var _value;
  bool nanoDate; // Used to sort by timestamp if timestamp in nanoseconds
  bool addId; // Used to indicate when to add the id when sorting

  Query(
    HopDocClient client,
    index,
    this._compoundQuery,
    this._field, {
    String isEqualTo,
    int isGreaterThan,
    int isGreaterThanOrEqualTo,
    int isLessThan,
    int isLessThanOrEqualTo,
    String contains,
    GeoDistanceQuery isWithinRadius,
    GeoBoxQuery isWithinBox,
    int at,
    Document after,
    int limit,
    String orderBy,
    this.addId,
    this.nanoDate,
  })  : assert((at == null || after == null) == true,
            "You cannot set both at and after in start filter method on a query"),
        super(client, index) {
    if (isEqualTo != null) {
      this._queryType = QueryType.IS_EQUAL_TO;
      this._value = isEqualTo;
    } else if (isGreaterThan != null) {
      this._queryType = QueryType.IS_GREATER_THAN;
      this._value = isGreaterThan;
    } else if (isGreaterThanOrEqualTo != null) {
      this._queryType = QueryType.IS_GREATER_THAN_OR_EQUAL_TO;
      this._value = isGreaterThanOrEqualTo;
    } else if (isLessThan != null) {
      this._queryType = QueryType.IS_LESS_THAN;
      this._value = isLessThan;
    } else if (isLessThanOrEqualTo != null) {
      this._queryType = QueryType.IS_LESS_THAN_OR_EQUAL_TO;
      this._value = isLessThanOrEqualTo;
    } else if (contains != null) {
      this._queryType = QueryType.CONTAINS;
      this._value = contains;
    } else if (isWithinRadius != null) {
      this._queryType = QueryType.IS_WITHIN_RADIUS;
      this._value = isWithinRadius;
    } else if (isWithinBox != null) {
      this._queryType = QueryType.IS_WITHIN_BOX;
      this._value = isWithinBox;
    } else if (at != null) {
      this._queryType = QueryType.START_AT;
      this._value = at;
    } else if (after != null) {
      this._queryType = QueryType.START_AFTER;
      this._value = after;
    } else if (limit != null) {
      this._queryType = QueryType.LIMIT;
      this._value = limit;
    } else if (orderBy != null) {
      this._queryType = QueryType.ORDER_BY;
      this._value = orderBy;
    }
  }

  Map<String, dynamic> get equalToBody {
    return {
      "match": {_field: _value}
    };
  }

  List<dynamic> get containsBody {
    return _value.split(" ").map((val) => {
      "wildcard": {_field: "*$val*"}
    }).toList();
  }

  Map<String, dynamic> comparisonBody(String comparison) {
    return {
      "range": {
        _field: {comparison: _value}
      }
    };
  }

  Map<String, dynamic> geoDistanceBody(GeoDistanceQuery query) {
    return {
      "geo_distance": {
        "distance": query.radius,
        query.field: {
          "lat": query.center.latitude,
          "lon": query.center.longitude,
        }
      }
    };
  }

  Map<String, dynamic> geoBoxBody(GeoBoxQuery query) {
    return {
      "geo_bounding_box": {
        query.field: {
          "top_left": {
            "lat": query.topLeft.latitude,
            "lon": query.topLeft.longitude
          },
          "bottom_right": {
            "lat": query.bottomRight.latitude,
            "lon": query.bottomRight.longitude
          }
        }
      }
    };
  }

  Map<String, dynamic> get compoundBody {
    switch (_queryType) {
      case QueryType.IS_EQUAL_TO:
        {
          (_compoundQuery["query"]["bool"]["must"] as List).add(equalToBody);
        }
        break;
      case QueryType.IS_GREATER_THAN:
        {
          (_compoundQuery["query"]["bool"]["must"] as List)
              .add(comparisonBody("gt"));
        }
        break;
      case QueryType.IS_GREATER_THAN_OR_EQUAL_TO:
        {
          (_compoundQuery["query"]["bool"]["must"] as List)
              .add(comparisonBody("gte"));
        }
        break;
      case QueryType.IS_LESS_THAN:
        {
          (_compoundQuery["query"]["bool"]["must"] as List)
              .add(comparisonBody("lt"));
        }
        break;
      case QueryType.IS_LESS_THAN_OR_EQUAL_TO:
        {
          (_compoundQuery["query"]["bool"]["must"] as List)
              .add(comparisonBody("lte"));
        }
        break;
      case QueryType.CONTAINS:
        {
          (_compoundQuery["query"]["bool"]["must"] as List).addAll(containsBody);
        }
        break;
      case QueryType.IS_WITHIN_RADIUS:
        {
          (_compoundQuery["query"]["bool"]["filter"] as List)
              .add(geoDistanceBody(_value));
        }
        break;
      case QueryType.IS_WITHIN_BOX:
        {
          (_compoundQuery["query"]["bool"]["filter"] as List)
              .add(geoBoxBody(_value));
        }
        break;
      case QueryType.START_AT:
        {
          _compoundQuery["from"] = _value;
        }
        break;
      case QueryType.START_AFTER:
        {
          final Document doc = _value;

          // doc.sort may have truncated the timestamp value is it is in nanoseconds range...
          // List searchAfter = doc.sort ?? [];

          // In order to search after a timestamp in the ns range, compute the nanosecondsSinceEpoch
          // from the field itself, not from the values returned by ES.
          List searchAfter = [];

          assert(doc.source != null,
              "Document provided to start after query must have a non-null source");
          try {
            for (Map<String, dynamic> sort in _compoundQuery["sort"]) {
              final String key = sort.keys.toList()[0];
              if (key == "_id") {
                searchAfter.add(doc.id);
                continue;
              }
              dynamic value = doc.source[key];
              // Convert to timestamp if its a time value
              try {
                value = this.nanoDate
                    ? TimeHelper.nanosecondsSinceEpoch(value)
                    : TimeHelper.millisecondsSinceEpoch(value);
              } catch (e) {}

              searchAfter.add(value);
            }
          } catch (e) {}

          _compoundQuery["search_after"] = searchAfter;
        }
        break;
      case QueryType.LIMIT:
        {
          _compoundQuery["size"] = _value;
        }
        break;
      case QueryType.ORDER_BY:
        {
          (_compoundQuery["sort"] as List).add({_field: _value});
          if (this.addId) (_compoundQuery["sort"] as List).add({"_id": "asc"});
        }
        break;
    }
    return _compoundQuery;
  }
}
