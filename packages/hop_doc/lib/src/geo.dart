class GeoPoint {
  final double latitude, longitude;
  GeoPoint({required this.latitude, required this.longitude});

  GeoPoint.fromJson(Map<String, dynamic> json)
      : latitude = json["location"]["latitude"],
        longitude = json["location"]["longitude"];
}
