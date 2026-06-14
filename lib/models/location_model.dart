class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? name;
  final String? placeType;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.name,
    this.placeType,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'name': name,
      };

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        address: json['address'] as String?,
        name: json['name'] as String?,
      );

  @override
  String toString() => name ?? address ?? '$latitude, $longitude';
}
