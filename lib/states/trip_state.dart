import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/directions.dart';
import 'package:google_maps_webservice/geolocation.dart';
import 'package:google_maps_webservice/places.dart';

class TripState extends ChangeNotifier {
  GoogleMapController _mapController;
  GoogleMapsDirections directions = GoogleMapsDirections();
  GoogleMapsPlaces placesRequest = GoogleMapsPlaces();
  GoogleMapsGeolocation geoLocation = GoogleMapsGeolocation();
  Location _currentLocation;
  List<Prediction> _requestedPredictions;
  Location get location => _currentLocation;
  Future<void> getMyLocation() async {

  }




  List<Prediction> get requestedPredictions => _requestedPredictions;
  getDirections({pointA, pointB}) {

  }
  Future<void> makePlaceRequest(String location) async {
      PlacesAutocompleteResponse response = await placesRequest.autocomplete(location);
      _requestedPredictions = response.predictions;
      notifyListeners();
  }
  onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    notifyListeners();

  }


  updateCamera(CameraUpdate cameraUpdate) {
    if(_mapController == null) {
      throw Exception("The map controller is null. Either set a value or pass a value via the onMapCreated function");
    }
    _mapController.animateCamera(cameraUpdate);
  }


  set mapController(GoogleMapController mapController) {
    _mapController = mapController;
  }


}