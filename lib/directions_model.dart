import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Directions {
  final LatLngBounds bounds;
  final List<PointLatLng> polylinePoints;
  final String totalDistance;
  final String totalDuration;
  final String duration_due_to_traffic;
  final String roadSummary;
  final String prediction;
  final String origin;
  final String destination;

  const Directions({
    @required this.bounds,
    @required this.polylinePoints,
    @required this.totalDistance,
    @required this.totalDuration,
    @required this.duration_due_to_traffic,
    @required this.roadSummary,
    @required this.prediction,
    @required this.origin,
    @required this.destination,
  });

  factory Directions.fromMap(Map<String, dynamic> map) {
    // Check if route is not available
    if ((map['routes'] as List).isEmpty) return null;

    // Get route information
    final data = Map<String, dynamic>.from(map['routes'][0]);

    // Bounds
    final northeast = data['bounds']['northeast'];
    final southwest = data['bounds']['southwest'];
    final bounds = LatLngBounds(
      northeast: LatLng(northeast['lat'], northeast['lng']),
      southwest: LatLng(southwest['lat'], southwest['lng']),
    );

    // Distance & Duration
    String distance = '';
    String duration = '';
    String due_to_traffic = '';
    String road = '';
    String origin = '';
    String destination = '';
    if ((data['legs'] as List).isNotEmpty) {
      final leg = data['legs'][0];
      distance = leg['distance']['text'];
      duration = leg['duration']['text'];
      due_to_traffic = leg['duration_in_traffic']['text'];
      origin = leg['start_address'];
      destination = leg['end_address'];
    }
    if (data['summary'] != null) {
      road = data['summary'];
    }

    String predictTraffic({String avg_time, String time_due_to_traffic}) {
      List list_time = [avg_time, time_due_to_traffic];
      List list_timeList = [];

      for (String item in list_time) {
        list_timeList.add(item.split(" "));
      }

      List time_in_minutes = [];

      for (List item in list_timeList) {
        int hour = int.parse(item[0]);
        int minute = int.parse(item[2]);
        int total = (hour * 60) + minute;
        time_in_minutes.add(total);
      }

      int difference = time_in_minutes[0] - time_in_minutes[1];
      String final_result_time;
      if (difference.abs() > 60) {
        int minutes = (difference.abs()) % 60;
        int hour = ((difference.abs()) / 60).floor();
        final_result_time = "$hour hr and $minutes mins";
      } else {
        final_result_time = "${difference.abs()} mins";
      }
      if (difference.isNegative) {
        return "Higher traffic, takes ${final_result_time} more than usual";
      } else if (difference == 0) {
        return "Usual traffic";
      } else {
        return "${final_result_time} faster, due to less traffic than usual";
      }
    }

    return Directions(
      origin: origin,
      destination: destination,
      bounds: bounds,
      polylinePoints:
          PolylinePoints().decodePolyline(data['overview_polyline']['points']),
      totalDistance: distance,
      totalDuration: duration,
      duration_due_to_traffic: due_to_traffic,
      roadSummary: road,
      prediction: predictTraffic(
        avg_time: duration,
        time_due_to_traffic: due_to_traffic,
      ),
    );
  }
}
