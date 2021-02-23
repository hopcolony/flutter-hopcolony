class GeoPoint {
  final double latitude, longitude;
  GeoPoint({this.latitude, this.longitude});

  GeoPoint.fromJson(Map<String, dynamic> json)
      : latitude = json["location"]["latitude"],
        longitude = json["location"]["longitude"];
}
