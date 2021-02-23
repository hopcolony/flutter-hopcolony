import 'package:hop_doc/src/geo.dart';
import 'doc.dart';
import 'queryable_reference.dart';

enum QueryType {
  IS_EQUAL_TO,
  IS_GREATER_THAN,
  IS_GREATER_THAN_OR_EQUAL_TO,
  IS_LESS_THAN,
  IS_LESS_THAN_OR_EQUAL_TO,
  IS_WITHIN_RADIUS,
  IS_WITHIN_BOX
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
    GeoDistanceQuery isWithinRadius,
    GeoBoxQuery isWithinBox,
  }) : super(client, index) {
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
    } else if (isWithinRadius != null) {
      this._queryType = QueryType.IS_WITHIN_RADIUS;
      this._value = isWithinRadius;
    } else if (isWithinBox != null) {
      this._queryType = QueryType.IS_WITHIN_BOX;
      this._value = isWithinBox;
    }
  }

  Map<String, dynamic> get equalToBody {
    return {
      "match": {_field: _value}
    };
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
    }
    return _compoundQuery;
  }
}
