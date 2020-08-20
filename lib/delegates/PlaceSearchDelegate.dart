import 'package:drivingapp/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';

class PlaceSearchDelegate extends SearchDelegate<Prediction> {
  final places = GoogleMapsPlaces(apiKey: API_KEY);

  @override
  List<Widget> buildActions(BuildContext context) {
    // TODO: implement buildActions
    return <Widget>[
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = "";
        },
      )
    ];
  }



  @override
  Widget buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    return IconButton(icon: Icon(Icons.arrow_back), onPressed: () {
      close(context, null);
    },);
  }

  @override
  Widget buildResults(BuildContext context) {
    Future<PlacesAutocompleteResponse> results = places
        .autocomplete(query, components: [Component(Component.country, "JM")]);
    return buildSearchResults(results);
  }



  FutureBuilder<PlacesAutocompleteResponse> buildSearchResults(Future<PlacesAutocompleteResponse> results) {
    return FutureBuilder(
      future: results,
      builder: (context, AsyncSnapshot<PlacesAutocompleteResponse> response) {
        print("connection state: ===================================> ${response.connectionState}");
        print("connection state: ===================================> ${response.hasData}");
        if(query == null || query == "")
          return Container();
        if(response.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!response.hasData) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("No places found for your query", style: Theme.of(context).textTheme.headline1,)
            ],
          );
        }



        return ListView.builder(itemCount: response.data?.predictions?.length,
            itemBuilder: (context, index) {
              Prediction prediction = response.data.predictions[index];

              return ListTile(
                leading: Icon(Icons.my_location),
                title: Text("${prediction.structuredFormatting.mainText}"),
                subtitle: Text("${prediction.description}"),
                onTap: () {
                  close(context, prediction);
                }
              );
            });
      });
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    Future<PlacesAutocompleteResponse> results = places
        .autocomplete(query, components: [Component(Component.country, "JM")]);

    return buildSearchResults(results);
  }
}
