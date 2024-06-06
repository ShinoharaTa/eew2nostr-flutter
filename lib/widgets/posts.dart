class EEWItem {
  final String id;
  final int serial;
  final String originTime;
  final String reportTime;
  final String place;
  final double latitude;
  final double longitude;
  final int depth;
  final String magnitude;
  final String forecast;

  EEWItem({
    required this.id,
    required this.serial,
    required this.originTime,
    required this.reportTime,
    required this.place,
    required this.latitude,
    required this.longitude,
    required this.depth,
    required this.magnitude,
    required this.forecast,
  });

  factory EEWItem.fromJson(Map<String, dynamic> json) {
    return EEWItem(
      id: json['id'],
      serial: json['serial'],
      originTime: json['originTime'],
      reportTime: json['reportTime'],
      place: json['place'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      depth: json['depth'],
      magnitude: json['magnitude'],
      forecast: json['forecast'],
    );
  }
}