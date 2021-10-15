import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:traffic_prediction/place_service.dart';

class LocationSearch extends SearchDelegate<Suggestion> {
  final sessionToken;
  PlaceApiProvider apiClient;
  LocationSearch(this.sessionToken) {
    apiClient = PlaceApiProvider(sessionToken);
  }
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    print(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder(
      future: query == "" ? null : apiClient.fetchSuggestions(query),
      builder: (context, snapShot) => query == ""
          ? Container(
              child: Text('Search for places'),
            )
          : snapShot.hasData
              ? ListView.builder(
                  itemBuilder: (context, i) => ListTile(
                    title: Text((snapShot.data[i] as Suggestion).description),
                    onTap: () {
                      query = (snapShot.data[i] as Suggestion).description;
                    },
                  ),
                  itemCount: snapShot.data.length,
                )
              : Container(
                  child: CircularProgressIndicator(),
                ),
    );
  }
}
