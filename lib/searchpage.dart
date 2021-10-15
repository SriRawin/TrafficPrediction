import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:traffic_prediction/place_info.dart';
import 'package:traffic_prediction/place_service.dart';
import 'package:traffic_prediction/responsive_template.dart';
import 'package:uuid/uuid.dart';

import '.env.dart';

enum locationType { origin, destination }

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _destinationController = TextEditingController();
  final _originController = TextEditingController();
  LatLng originCoordinates;
  LatLng destinationCoordinates;
  PlaceInfo routeDetails;

  PlaceApiProvider apiClient;
  bool isOrigin = false;

  String origin = "";
  String destination = "";
  String query = "";

  final apiKey = googleAPIkey;
  Future<PlaceInfo> findCoordinates(
      {String startPoint, String endPoint}) async {
    final origin_request =
        "https://maps.googleapis.com/maps/api/geocode/json?address=$startPoint&components=country:in&key=$apiKey";
    final destination_request =
        "https://maps.googleapis.com/maps/api/geocode/json?address=$endPoint&components=country:in&key=$apiKey";
    final origin_response = await http.get(Uri.parse(origin_request));
    final destination_response = await http.get(Uri.parse(destination_request));
    final origin_result = json.decode(origin_response.body);
    final destination_result = json.decode(destination_response.body);
    final origin_body = origin_result['results'][0]['geometry']['location'];
    final destination_body =
        destination_result['results'][0]['geometry']['location'];
    originCoordinates = LatLng(origin_body['lat'], origin_body['lng']);
    destinationCoordinates =
        LatLng(destination_body['lat'], destination_body['lng']);
    routeDetails = PlaceInfo(
        origin, destination, originCoordinates, destinationCoordinates);

    return routeDetails;
  }

  void _search() async {
    final sessionToken = Uuid().v4();
    apiClient = PlaceApiProvider(sessionToken);
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _originController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveTemplate(
      builder: (context, size) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            leading: IconButton(

              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back,
                color: Colors.blue.shade600,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(size.height * 0.14),
              child: Padding(
                padding: EdgeInsets.fromLTRB(size.width * 0.05, 0,
                    size.width * 0.01, size.height * 0.02),
                child: Column(
                  children: [
                    AddressSearch(
                      editingController: _originController,
                      iconData: Icons.my_location,
                      hintText: "Origin",
                      enabled: true,
                      onTap: () {
                        setState(() {
                          isOrigin = true;
                        });
                        _search();
                      },
                      onChanged: (text) {
                        setState(() {
                          query = text;
                        });
                      },
                      onSumbitted: (text) {
                        setState(() {
                          origin = text;
                          query = "";
                        });
                      },
                    ),
                    SizedBox(
                      height: size.height * 0.02,
                    ),
                    AddressSearch(
                      editingController: _destinationController,
                      iconData: Icons.location_on_rounded,
                      hintText: "Destination",
                      enabled: true,
                      onTap: () {
                        setState(() {
                          isOrigin = false;
                        });
                        _search();
                      },
                      onChanged: (text) {
                        setState(() {
                          query = text;
                        });
                      },
                      onSumbitted: (text) {
                        setState(() {
                          destination = text;
                          query = "";
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.height * 0.02,
                ),
                child: Row(
                  children: [
                    Spacer(),
                    GestureDetector(
                      onTap: () async {
                        PlaceInfo result = await findCoordinates(
                            startPoint: origin, endPoint: destination);
                        Navigator.pop(context, result);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.06,
                          vertical: size.height * 0.016,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            size.height * 0.008,
                          ),
                        ),
                        child: Text(
                          "Done",
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w700,
                            fontSize: size.height * 0.022,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future:
                      query == "" ? null : apiClient.fetchSuggestions(query),
                  builder: (context, snapShot) => query == ""
                      ? Container(
                          child: Text(
                            'Search for places',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: size.height * 0.022,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : snapShot.hasData
                          ? ListView.builder(
                              itemBuilder: (context, i) => ListTile(
                                title: Text(
                                  (snapShot.data[i] as Suggestion).description,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: size.height * 0.026,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () {
                                  if (isOrigin == true) {
                                    _originController.text =
                                        (snapShot.data[i] as Suggestion)
                                            .description;
                                    origin = _originController.text;
                                  } else {
                                    _destinationController.text =
                                        (snapShot.data[i] as Suggestion)
                                            .description;
                                    destination = _destinationController.text;
                                  }
                                },
                              ),
                              itemCount: snapShot.data.length,
                            )
                          : Container(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddressSearch extends StatelessWidget {
  final IconData iconData;
  final TextEditingController editingController;
  final String hintText;
  final Function onTap;
  final bool enabled;
  final Function onChanged;
  final Function onSumbitted;

  AddressSearch({
    this.iconData,
    this.editingController,
    this.hintText,
    this.onTap,
    this.onChanged,
    this.enabled,
    this.onSumbitted,
  });
  @override
  Widget build(BuildContext context) {
    return ResponsiveTemplate(
      builder: (context, size) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(size.height * 0.012),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(
                  size.height * 0.008,
                ),
              ),
              child: Icon(
                iconData,
                size: size.height * 0.03,
                color: Colors.blue,
              ),
            ),
            SizedBox(
              width: size.width * 0.03,
            ),
            Container(
              height: size.height * 0.05,
              width: size.width * 0.7,
              child: TextField(
                controller: editingController,
                enabled: enabled,
                onTap: onTap,
                onSubmitted: onSumbitted,
                cursorColor: Colors.blue.shade800,
                onChanged: onChanged,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: size.height * 0.012,
                  ),
                  hintText: hintText,
                  hintStyle: TextStyle(
                    fontSize: size.height * 0.02,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade300,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue.shade600,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.blue.shade600,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
