import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import "package:intl/intl.dart";
import 'package:location/location.dart';
import 'package:traffic_prediction/directions.dart';
import 'package:traffic_prediction/directions_model.dart';
import 'package:traffic_prediction/mapControls.dart';
import 'package:traffic_prediction/page_transition.dart';
import 'package:traffic_prediction/place_info.dart';
import 'package:traffic_prediction/responsive_template.dart';
import 'package:traffic_prediction/searchpage.dart';

import '.env.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController _mapController;
  List<Marker> myMarker = [];
  Directions _info;
  BitmapDescriptor customIcon;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _currentLocation() async {
    LocationData currentLocation;
    var location = Location();
    try {
      currentLocation = await location.getLocation();
    } on Exception {
      currentLocation = null;
    }

    _mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        tilt: 0,
        bearing: 0,
        target: LatLng(currentLocation.latitude, currentLocation.longitude),
        zoom: 17.0,
      ),
    ));
  }

  void _addMarker({LatLng origin, LatLng destination}) {
    setState(() {
      myMarker = [];
      myMarker.add(
        Marker(
          markerId: MarkerId(
            origin.toString(),
          ),
          position: origin,
          visible: true,
          icon: customIcon,
        ),
      );
      myMarker.add(
        Marker(
          markerId: MarkerId(
            destination.toString(),
          ),
          position: destination,
          visible: true,
        ),
      );
    });
  }

  customMarker(context) {
    ImageConfiguration configuration = createLocalImageConfiguration(context);
    BitmapDescriptor.fromAssetImage(configuration, "images/red_marker.png")
        .then((icon) {
      setState(() {
        customIcon = icon;
      });
    });
  }

  Future<void> getPoints({LatLng origin, LatLng destination}) async {
    final directions = await MapDirections()
        .getDirections(origin: origin, destination: destination);
    setState(() {
      _info = directions;
    });
    _addMarker(origin: origin, destination: destination);
  }

  Future<Widget> showRouteAndTrafficInformation(
      {double width, double height}) async {
    Future.delayed(Duration(milliseconds: 10), () {
      _mapController.animateCamera(
        CameraUpdate.zoomBy(
          -1,
          Offset(
            width * 0.5,
            0,
          ),
        ),
      );
    });

    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: false,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        topLeft: Radius.circular(height * 0.03),
        topRight: Radius.circular(height * 0.03),
      )),
      backgroundColor: Colors.grey.shade300,
      builder: (context) => BottomSheet(
        mapController: _mapController,
        routeDetails: _info,
      ),
    );
    ;
  }

  @override
  Widget build(BuildContext context) {
    customMarker(context);
    return Scaffold(
      backgroundColor: Colors.white70,
      body: ResponsiveTemplate(builder: (context, size) {
        return Stack(
          fit: StackFit.expand,
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) async {
                _mapController = await controller;
              },
              markers: Set.from(myMarker),
              trafficEnabled: false,
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              polylines: {
                if (_info != null)
                  Polyline(
                    polylineId: const PolylineId('overview_polyline'),
                    color: Colors.red.shade500.withOpacity(0.7),
                    width: 5,
                    points: _info.polylinePoints
                        .map((e) => LatLng(e.latitude, e.longitude))
                        .toList(),
                  ),
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(12.6819, 79.9888),
                zoom: 14,
              ),
            ),
            MapControls(
              showDirectionButton: _info != null ? true : false,
              locationButton: _currentLocation,
              directionButton: () async {
                _mapController.moveCamera(
                  CameraUpdate.newLatLngBounds(_info.bounds, 10),
                );

                showRouteAndTrafficInformation(
                  height: size.height,
                  width: size.width,
                );
              },
              searchButton: () async {
                PlaceInfo _placeInfo;
                final finalResult = await Navigator.push(
                  context,
                  SlideUp(
                    nextPage: SearchPage(),
                  ),
                );

                _placeInfo = finalResult;
                if (_placeInfo != null) {
                  await getPoints(
                      origin: _placeInfo.originCoordinates,
                      destination: _placeInfo.destinationCoordinates);

                  _mapController.moveCamera(
                    CameraUpdate.newLatLngBounds(_info.bounds, 10),
                  );

                  showRouteAndTrafficInformation(
                    height: size.height,
                    width: size.width,
                  );
                }
              },
            ),
          ],
        );
      }),
    );
  }
}

class BottomSheet extends StatefulWidget {
  final Directions routeDetails;
  final GoogleMapController mapController;
  BottomSheet({this.routeDetails, this.mapController});

  @override
  _BottomSheetState createState() => _BottomSheetState();
}

class _BottomSheetState extends State<BottomSheet> {
  int timeInMinutes(String time) {
    List time_list = [];
    time_list = time.split(" ");
    int hour = int.parse(time_list[0]);
    int minute = int.parse(time_list[2]);
    int total = (hour * 60) + minute;
    return total;
  }

  Future<List> suggestedTime() async {
    final apiKey = googleAPIkey;
    int n = 24;
    int i;
    var initial = timeInMinutes(widget.routeDetails.duration_due_to_traffic);
    var now = DateTime.now();
    var formatDate = DateFormat("h:mm a dd,MMMM");
    List duration_list = [];
    int difference = 0;

    for (i = 1; i <= n; i++) {
      int timeInSeconds;
      var newTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour + i,
        00,
        now.second,
      );
      timeInSeconds = (newTime.millisecondsSinceEpoch / 1000).floor();
      var time = formatDate.format(newTime);
      final suggestedTimeRequest =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${widget.routeDetails.origin}&destination=${widget.routeDetails.destination}&departure_time=$timeInSeconds&units=metric&key=$apiKey";
      final response = await http.get(Uri.parse(suggestedTimeRequest));

      final result = json.decode(response.body);
      String duration =
          result['routes'][0]['legs'][0]['duration_in_traffic']['text'];
      difference = initial - timeInMinutes(duration);

      if (timeInMinutes(duration) < initial) {
        duration_list.add([time, duration, difference]);
      }
      // duration_list.add([time, duration, difference]);
    }

    return duration_list;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveTemplate(
      builder: (context, size) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: size.height * 0.01,
              ),
              Row(
                children: [
                  SizedBox(
                    width: size.width * 0.03,
                  ),
                  Text(
                    'Route-Traffic Information',
                    style: TextStyle(
                      fontSize: size.height * 0.03,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    color: Colors.grey.shade700,
                    onPressed: () {
                      widget.mapController.animateCamera(
                        CameraUpdate.newLatLngBounds(
                            widget.routeDetails.bounds, 20),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Divider(
                height: 0,
                thickness: 2,
                endIndent: 2,
                indent: 2,
              ),
              SizedBox(
                height: size.height * 0.01,
              ),
              Row(
                children: [
                  SizedBox(
                    width: size.width * 0.03,
                  ),
                  //here
                  Expanded(
                    child: Text(
                      "Road - ${widget.routeDetails.roadSummary}",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: size.height * 0.022,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: size.height * 0.01,
              ),
              Row(
                children: [
                  SizedBox(
                    width: size.width * 0.03,
                  ),
                  //here
                  Text(
                    "If you start now",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: size.height * 0.024,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: size.height * 0.01,
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  size.width * 0.03,
                  size.height * 0.004,
                  size.width * 0.02,
                  size.height * 0.016,
                ),
                width: size.width,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(size.height * 0.02),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          color: Colors.blue.shade800,
                          size: size.height * 0.04,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              widget.routeDetails.duration_due_to_traffic,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: size.height * 0.032,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              width: size.width * 0.01,
                            ),
                            Text(
                              "(${widget.routeDetails.totalDistance})",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: size.height * 0.02,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: size.height * 0.002,
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: size.width * 0.01,
                        ),
                        FittedBox(
                          child: Text(
                            "${widget.routeDetails.prediction}",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: size.height * 0.022,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: size.height * 0.01,
              ),
              Divider(
                thickness: 1.5,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: size.width * 0.03),
                      child: Text(
                        "Recommended travel timings",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: size.height * 0.024,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: size.height * 0.01,
                    ),
                    Expanded(
                      child: FutureBuilder(
                        future: suggestedTime(),
                        builder: (context, snapShot) {
                          if (snapShot.connectionState ==
                              ConnectionState.done) {
                            return snapShot.data.length != 0
                                ? ListView.builder(
                                    physics: BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: EdgeInsets.only(
                                          bottom: size.width * 0.04,
                                        ),
                                        padding: EdgeInsets.fromLTRB(
                                          size.width * 0.03,
                                          size.height * 0.01,
                                          size.width * 0.02,
                                          size.height * 0.014,
                                        ),
                                        width: size.width,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                              size.height * 0.02),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              snapShot.data[index][0],
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: size.height * 0.02,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.baseline,
                                              textBaseline:
                                                  TextBaseline.alphabetic,
                                              children: [
                                                Text(
                                                  "Typically ",
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize:
                                                        size.height * 0.029,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                Text(
                                                  snapShot.data[index][1],
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize:
                                                        size.height * 0.032,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: size.width * 0.01,
                                                ),
                                                Text(
                                                  "(${widget.routeDetails.totalDistance})",
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize:
                                                        size.height * 0.02,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: size.height * 0.002,
                                            ),
                                            Row(
                                              children: [
                                                SizedBox(
                                                  width: size.width * 0.01,
                                                ),
                                                FittedBox(
                                                  child: Text(
                                                    "${snapShot.data[index][2]} mins faster than normal, due to less traffic",
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontSize:
                                                          size.height * 0.022,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    itemCount: snapShot.data.length,
                                  )
                                : Center(
                                    child: Text(
                                      "No recommendations",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: size.height * 0.022,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  );
                          } else {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
