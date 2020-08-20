import 'package:drivingapp/colors.dart';
import 'package:drivingapp/states/trip_state.dart';
import 'package:drivingapp/trip_search_delegate.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';

class PlaceSearch extends StatefulWidget {
  final bool focusOnFrom;
  PlaceSearch({this.focusOnFrom = true});
  @override
  _PlaceSearchState createState() => _PlaceSearchState();
}

class _PlaceSearchState extends State<PlaceSearch> {
  MaterialColor primaryColor = createMaterialColor(Color(0xFF1F1F1F));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: Column(
        children: <Widget>[
          TripSearchDelegate(),
          Expanded(
            child: Consumer<TripState>(builder: (context, tripState, child)  {
              return ListView.builder(
                itemCount: tripState.requestedPredictions?.length,
                itemBuilder: (BuildContext context, int index) {
                  if(tripState.requestedPredictions == null) {
                    return Container();
                  }
//                 Prediction prediction = tripState.requestedPredictions[index];
                 return Container(
                   child: ListTile(
                     title: Text("Hello World",),
                     subtitle: Text("Lorem Ipsum bullshit text."),
                     onTap: () {
                       
                     }
                   )
                 );
              },);
            }),
          )



        ],
      ),
    ));
  }
}
