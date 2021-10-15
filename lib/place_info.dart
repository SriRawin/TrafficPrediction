import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceInfo {
  final String origin;
  final String destination;
  final LatLng originCoordinates;
  final LatLng destinationCoordinates;

  PlaceInfo(this.origin, this.destination, this.originCoordinates,
      this.destinationCoordinates);
}
