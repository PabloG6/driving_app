import 'dart:async';
import 'dart:math';
import 'package:drivingapp/modals/courier.modal.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivingapp/colors.dart';
import 'package:drivingapp/constants.dart';
import 'package:drivingapp/delegates/PlaceSearchDelegate.dart';
import 'package:drivingapp/pages/login_page.dart';
import 'package:drivingapp/pages/profile.page.dart';
import 'package:drivingapp/pages/ride_history.page.dart';
import 'package:drivingapp/places_search.dart';
import 'package:drivingapp/states/trip_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_webservice/geocoding.dart' as MapsWebService;
import 'package:google_maps_webservice/places.dart' as Places;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  MaterialColor primaryColor = createMaterialColor(Color(0xFF3a86ff));

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<TripState>(create: (context) => TripState())
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
            primarySwatch: Colors.indigo,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            inputDecorationTheme: Theme.of(context)
                .inputDecorationTheme
                .copyWith(
                    labelStyle: Theme.of(context).textTheme.bodyText1.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor))),
        home: SafeArea(child: LoginPage()),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleSignIn googleSignIn = GoogleSignIn();

  void signOutGoogle() async {
    await googleSignIn.signOut().whenComplete(() => Navigator.of(context)
        .pushReplacement(
            MaterialPageRoute(builder: (BuildContext context) => LoginPage())));
  }

  Places.Prediction fromPrediction;
  Places.Prediction toPrediction;
  final rideCollection = Firestore.instance.collection("rides");
  MaterialColor primaryColor = createMaterialColor(Color(0xFF3a86ff));
  TextEditingController fromEditingController = TextEditingController();
  TextEditingController toEditingController = TextEditingController();
  Location _location = Location();
  bool _hasService;
  Set<Marker> _markers = Set();
  Set<Polyline> _polyLineSet = Set();
  Completer<GoogleMapController> _controller = Completer();
  PermissionStatus _hasPermission;
  final LatLng halfWayTree = LatLng(18.0023101, -76.7942821);
  CameraPosition _initialPosition = CameraPosition(
    target: LatLng(18.0023101, -76.7942821),
    zoom: 14.4746,
  );
  FirebaseAuth auth = FirebaseAuth.instance;
  double distanceBetweenRoutes = 0;
  int totalPrice = 0;
  LatLng from;
  LatLng to;
  GoogleMapController mapController;
  FirebaseUser user;

  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  void initState() {
    super.initState();
    _controller.future.then((value) {
      mapController = value;
    });

    auth.currentUser().then((user) {
      this.user = user;
    });
  }

  //everytime u create a new location reset it.
  Future<LocationData> getMyLocation() async {
    if (!_controller.isCompleted) mapController = await _controller.future;

    LocationData locationData = await _location.getLocation();
    LatLng latlng = LatLng(locationData.latitude, locationData.longitude);
    from = latlng;
    CameraPosition cameraPosition = CameraPosition(target: latlng, zoom: 15);
    final geocoding = MapsWebService.GoogleMapsGeocoding(apiKey: API_KEY);
    MapsWebService.GeocodingResponse geocodingResponse =
        await geocoding.searchByLocation(
            MapsWebService.Location(latlng.latitude, latlng.longitude));

    MapsWebService.GeocodingResult address = geocodingResponse.results.first;

    fromEditingController.value = TextEditingValue(
        text: address.formattedAddress,
        selection: TextSelection.fromPosition(
            TextPosition(offset: address.formattedAddress.length)));
    mapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    return locationData;
  }

  Future<void> getDestination() async {
    final geocoding = MapsWebService.GoogleMapsGeocoding(apiKey: API_KEY);

    MapsWebService.GeocodingResponse response = await geocoding
        .searchByLocation(MapsWebService.Location(18.0023101, -76.7942821));

    final address = response.results.first;
    toEditingController.value = TextEditingValue(
        text: address.formattedAddress,
        selection: TextSelection.fromPosition(
            TextPosition(offset: address.formattedAddress.length)));
  }

  getDirections(BuildContext context) async {
    print("Hello World");
    distanceBetweenRoutes = 0;
    if (fromPrediction == null || toPrediction == null) {
      return;
    }

    Places.GoogleMapsPlaces places = Places.GoogleMapsPlaces(apiKey: API_KEY);
    print("${fromPrediction.placeId}");
    print("${toPrediction.placeId}");

    final fromPlace =
        (await places.getDetailsByPlaceId(fromPrediction.placeId)).result;
    final toPlace =
        (await places.getDetailsByPlaceId(toPrediction.placeId)).result;

    PolylinePoints polylinePoints = PolylinePoints();

    final directions = await polylinePoints.getRouteBetweenCoordinates(
        API_KEY,
        PointLatLng(
            fromPlace.geometry.location.lat, fromPlace.geometry.location.lng),
        PointLatLng(
            toPlace.geometry.location.lat, toPlace.geometry.location.lng),
        travelMode: TravelMode.driving);

    for (int i = 0; i < directions.points.length - 1; i++) {
      distanceBetweenRoutes += _coordinateDistance(
        directions.points[i].latitude,
        directions.points[i].longitude,
        directions.points[i + 1].latitude,
        directions.points[i + 1].longitude,
      );
    }

    print("distance between routes: $distanceBetweenRoutes");
    totalPrice = (distanceBetweenRoutes * 140).floor();
    print("total price: $totalPrice");
    List<LatLng> points = [];
    directions.points.forEach((element) {
      print("${element.latitude}, ${element.longitude}");
      points.add(LatLng(element.latitude, element.longitude));
    });

    this.from = LatLng(
        fromPlace.geometry.location.lat, fromPlace.geometry.location.lng);
    this.to =
        LatLng(toPlace.geometry.location.lat, toPlace.geometry.location.lng);

    setState(() {
      _polyLineSet.clear();
      _polyLineSet.add(Polyline(
          polylineId: PolylineId("randomId"),
          points: points,
          color: Colors.blue,
          width: 4));
      print("hello world");
      _markers.clear();
      _markers.add(Marker(
          markerId: MarkerId(
            "toLocation",
          ),
          position: LatLng(
              toPlace.geometry.location.lat, toPlace.geometry.location.lng)));
      _markers.add(Marker(
          markerId: MarkerId(
            "fromLocation",
          ),
          position: LatLng(fromPlace.geometry.location.lat,
              fromPlace.geometry.location.lng)));
    });
    double minLatitude =
        to.latitude > from.latitude ? from.latitude : to.latitude;
    double minLongitude =
        to.longitude > from.longitude ? from.longitude : to.longitude;

    double maxLongitude =
        to.longitude > from.longitude ? to.longitude : from.longitude;
    double maxLatitude =
        to.latitude > from.latitude ? to.latitude : from.latitude;
    LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLatitude, minLongitude),
        northeast: LatLng(maxLatitude, maxLongitude));
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 70);
    mapController.animateCamera(cameraUpdate);
  }

  void panMap(Places.Prediction prediction) async {
    Places.GoogleMapsPlaces places = Places.GoogleMapsPlaces(apiKey: API_KEY);
    final fromLocation =
        (await places.getDetailsByPlaceId(prediction.placeId)).result;
    CameraPosition cPosition = CameraPosition(
      zoom: 12,
      target: LatLng(fromLocation.geometry.location.lat,
          fromLocation.geometry.location.lng),
    );

    _markers.clear();
    _markers.add(Marker(
        markerId: MarkerId('toLocation'),
        position: LatLng(fromLocation.geometry.location.lat,
            fromLocation.geometry.location.lng)));
    setState(() {});
    mapController
        .animateCamera(CameraUpdate.newCameraPosition(cPosition))
        .then((_) {
      print("completed moving map happened no error occured");
    }).catchError((error) {
      print(error);
      print("an unknown error has occured lol");
    });
  }

  String get pickup => fromPrediction?.structuredFormatting?.mainText;

  String get dropOff => toPrediction?.structuredFormatting?.mainText;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 360, height: 740);
    FirebaseUser user = Provider.of<FirebaseUser>(context);
    return Scaffold(
        drawer: Drawer(
            child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                    height: 180,
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  MultiProvider(
                                                    providers: [
                                                      StreamProvider<FirebaseUser>.value(value: FirebaseAuth.instance.onAuthStateChanged)
                                                    ],
                                                      child: ProfilePage())));
                                    },
                                    child: CircleAvatar(
                                      child: Text(
                                        "P",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .copyWith(
                                                fontSize: 20,
                                                color: Colors.white),
                                      ),
                                      radius: 32,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text("${user?.email}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1
                                            .copyWith(color: Colors.grey)),
                                  )
                                ]),
                          ),
                          Text("E Transit",
                              style: Theme.of(context).textTheme.headline5),
                          Text("For all your transportation needs",
                              style: Theme.of(context).textTheme.subtitle2)
                        ])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Divider(),
                ),
                ListView(shrinkWrap: true, children: <Widget>[
                  ListTile(
                    title: Text("Profile",
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2
                            .copyWith(fontSize: 18)),
                    subtitle: Text("See Important Profile Information",
                        style: Theme.of(context)
                            .textTheme
                            .caption
                            .copyWith(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (context) {
                        return ProfilePage();
                      }));
                    },
                  ),
                  ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => RideHistory()));
                      },
                      title: Text(
                        "Ride History",
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2
                            .copyWith(fontSize: 18),
                      ),
                      subtitle: Text("See your ride and payment history",
                          style: Theme.of(context)
                              .textTheme
                              .caption
                              .copyWith(fontWeight: FontWeight.w500))),
                  ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => LoginPage()));
                      },
                      title: Text(
                        "Log out",
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2
                            .copyWith(fontSize: 18),
                      ),
                      subtitle: Text("Sign out of the app",
                          style: Theme.of(context)
                              .textTheme
                              .caption
                              .copyWith(fontWeight: FontWeight.w500))),

                ])
              ],
            ),
          ),
        )),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 200),
          child: FloatingActionButton(
            child: Icon(Icons.my_location),
            mini: true,
            onPressed: () {
              getMyLocation();
            },
          ),
        ),
        body: SafeArea(
            child: Stack(
          children: <Widget>[
            GoogleMap(
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              markers: _markers,
              initialCameraPosition: _initialPosition,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              polylines: _polyLineSet,
              onMapCreated: (GoogleMapController mapController) {
                if (!_controller.isCompleted)
                  _controller.complete(mapController);
                getMyLocation();
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Card(
                    margin: EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(0))),
                    child: Padding(
                      padding:
                          EdgeInsets.only(bottom: ScreenUtil().setHeight(12)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          ListTile(
                              trailing: Icon(Icons.chevron_right),
                              title: Text("Pickup",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      .copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade500)),
                              subtitle: Text(pickup ?? "Select your pickup",
                                  style: Theme.of(context).textTheme.bodyText1),
                              onTap: () async {
                                final p = await showSearch(
                                    context: context,
                                    delegate: PlaceSearchDelegate());
                                setState(() {
                                  print("setState called");
                                  fromPrediction = p;
                                  panMap(fromPrediction);
                                  getDirections(context);
                                });
                              }),
                          ListTile(
                            trailing: Icon(Icons.chevron_right),
                            title: Text(
                              "Drop Off",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  .copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey),
                            ),
                            subtitle: Text(
                                dropOff ?? "Select your drop off here.",
                                style: Theme.of(context).textTheme.bodyText1),
                            onTap: () async {
                              Places.Prediction p = await showSearch(
                                  context: context,
                                  delegate: PlaceSearchDelegate());
                              setState(() {
                                this.toPrediction = p;
                                print("set state for to location called");
                                getDirections(context);
                              });
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                  ButtonTheme(
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      minWidth: double.infinity,
                      child: RaisedButton(
                          child: Text("Request Ride",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1
                                  .copyWith(color: Colors.white, fontSize: 16)),
                          onPressed: () {
                            showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return MultiProvider(
                                      providers: [
                                        StreamProvider<FirebaseUser>.value(
                                            value: FirebaseAuth
                                                .instance.onAuthStateChanged)
                                      ],
                                      child: CourierModal(
                                        startLocation: from,
                                        endLocation: to,
                                        polylines: _polyLineSet,
                                        markers: _markers,
                                        distance: this.distanceBetweenRoutes,
                                      ));
                                }).then((_) {
                              print(
                                  "done sending ride need to do something else here");
                            });
                          }))
                ],
              ),
            ),
            Positioned(
                top: 16,
                left: 24,
                child: Builder(
                  builder: (context) => IconButton(
                      icon: Icon(Icons.menu, color: Colors.black),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      }),
                )),
          ],
        )));
  }

  //sends a ride request to the database for processing
  void requestRide(BuildContext context) {
    rideCollection.add({
      "fromLat": from?.latitude ?? 0,
      "toLat": to?.latitude ?? 0,
      "fromLong": from?.longitude ?? 0,
      "toLong": to?.longitude ?? 0,
      "pickup": pickup,
      "dropoff": dropOff,
      "price": totalPrice,
    }).catchError((onError) {
      print(onError.toString());
      Scaffold.of(context).showSnackBar(SnackBar(
          content: Text(
              "An unexpected error has occured, please try again later.")));
    }).then((value) {
      print("document ID: ${value?.documentID}");
      Scaffold.of(context).showSnackBar(SnackBar(
          content: Text(
              "Request retrieved, awaiting response from available drivers.")));
    });
  }

  @override
  void didUpdateWidget(MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  Widget buildLocationPreviewWidget(
    BuildContext context, {
    onPressed: GestureTapCallback,
    String hintText = " ",
    TextStyle hintStyle,
    String text = " ",
    TextStyle textStyle,
    textColor,
  }) {
    return InkWell(
      onTap: () => onPressed(),
      child: Container(
          height: ScreenUtil().setHeight(92),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "$hintText",
                  style: hintStyle,
                ),
              ),
              Expanded(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("${text ?? ''}"),
                      Icon(
                        Icons.chevron_right,
                        size: 32,
                      )
                    ]),
              )
            ],
          )),
    );
  }
}
