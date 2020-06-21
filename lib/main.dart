import 'dart:async';

import 'package:drivingapp/colors.dart';
import 'package:drivingapp/constants.dart';
import 'package:drivingapp/places_search.dart';
import 'package:drivingapp/states/trip_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_webservice/geocoding.dart' as MapsWebService;
import 'package:location/location.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  MaterialColor primaryColor = createMaterialColor(Color(0xFF3a86ff));

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<TripState>(create: (context) => TripState(),),

      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          backgroundColor: primaryColor.shade500,
          primarySwatch: primaryColor,
          cardTheme: CardTheme(),

          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  MaterialColor primaryColor = createMaterialColor(Color(0xFF3a86ff));
  TextEditingController fromEditingController = TextEditingController();
  TextEditingController toEditingController = TextEditingController();
  Location _location = Location();
  bool _hasService;
  Set<Polyline> _polyLineSet = Set();
  Completer<GoogleMapController> _controller = Completer();
  PermissionStatus _hasPermission;
  final LatLng halfWayTree = LatLng(18.0023101, -76.7942821);
  CameraPosition _initialPosition = CameraPosition(
    target: LatLng(18.0023101, -76.7942821),
    zoom: 14.4746,
  );

  LatLng from;
  GoogleMapController mapController;
//  String _mapStyle;

  @override
  void initState() {
    super.initState();

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

  void combinePolyLines() {
    _polyLineSet.clear();
    _polyLineSet.addAll([
      Polyline(
          polylineId: PolylineId("destination"),
          points: <LatLng>[from, halfWayTree])
    ]);
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, width: 360, height: 740);
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
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
        child: FutureBuilder<LocationData>(
            future: getMyLocation(),
            builder: (context, snapshot) {


              return Stack(
                children: <Widget>[
                  GoogleMap(
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                    initialCameraPosition: _initialPosition,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    polylines: _polyLineSet,
                    onMapCreated: (GoogleMapController mapController) {
                      if (!_controller.isCompleted)
                        _controller.complete(mapController);
//                      mapController.setMapStyle(this._mapStyle);
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(
                          vertical: ScreenUtil().setHeight(14),
                          horizontal: ScreenUtil().setWidth(10)),
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: ScreenUtil().setWidth(8),
                            right: ScreenUtil().setHeight(8.0),
                            bottom: ScreenUtil().setHeight(28),
                            top: ScreenUtil().setWidth(8)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            InkWell(
                              onTap: () {
                                print("navigation to place search ===>");
                                Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) {
                                      return PlaceSearch();
                                    }));
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical:
                                                ScreenUtil().setHeight(12.0),
                                            horizontal:
                                                ScreenUtil().setWidth(4)),
                                        child: buildLocationPreviewWidget(
                                            context,
                                            text: "15 DriveWay Avenue",
                                            hintText: "Pickup",
                                            hintStyle: Theme.of(context)
                                                .textTheme
                                                .bodyText1
                                                .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize:
                                                        ScreenUtil().setSp(14),
                                                    color: Color(0xFFA1A1A1)),
                                            textStyle: Theme.of(context)
                                                .textTheme
                                                .bodyText2
                                                .copyWith(
                                                    fontSize:
                                                        ScreenUtil().setSp(16),
                                                    fontWeight:
                                                        FontWeight.bold)),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Divider(
                              indent: 16,
                              endIndent: 16,
                              height: 12,
                              thickness: 1.5,
                              color: Colors.grey.shade200,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(children: <Widget>[
                                Expanded(
                                  child: Padding(
                                      padding: EdgeInsets.only(
                                          top: ScreenUtil().setHeight(4.0),
                                          bottom: ScreenUtil().setHeight(4.0),
                                          left: ScreenUtil().setWidth(4),
                                          right: ScreenUtil().setWidth(4)),
                                      child: buildLocationPreviewWidget(context,
                                          text: "32 Freeway City Station",
                                          hintText: "Dropoff",
                                          hintStyle: Theme.of(context)
                                              .textTheme
                                              .bodyText1
                                              .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      ScreenUtil().setSp(14),
                                                  color: Color(0xFFA1A1A1)),
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodyText2
                                              .copyWith(
                                                  fontSize:
                                                      ScreenUtil().setSp(16),
                                                  fontWeight:
                                                      FontWeight.bold))),
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
      ),
    );
  }

  Widget buildLocationPreviewWidget(
    BuildContext context, {
    String hintText = " ",
    TextStyle hintStyle,
    String text = " ",
    TextStyle textStyle,
    textColor,
  }) {
    return Container(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Text(
            "$hintText",
            style: hintStyle,
          ),
        ),
        Text("$text", style: textStyle),
      ],
    ));
  }
}
