import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class ConfirmRidePage extends StatefulWidget {
  final LatLng from;
  final LatLng to;
  final DocumentSnapshot driver;
  final DocumentSnapshot courier;
  final double distance;

  final Set polylines;
  final Set markers;

  ConfirmRidePage(
      {this.from,
      this.to,
      this.courier,
      this.driver,
      this.distance,
      this.polylines,
      this.markers});

  @override
  _ConfirmRidePageState createState() => _ConfirmRidePageState();
}

class _ConfirmRidePageState extends State<ConfirmRidePage> {
  Firestore firestore = Firestore.instance;
  CollectionReference couriersCollection;
  GlobalKey<ScaffoldState> scaffoldState = GlobalKey();

  @override
  void initState() {
    super.initState();
    couriersCollection = firestore.collection("couriers");
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.courier.data["price_per_km"] * widget.distance;
    double minLatitude = widget.to.latitude > widget.from.latitude
        ? widget.from.latitude
        : widget.to.latitude;
    double minLongitude = widget.to.longitude > widget.from.longitude
        ? widget.from.longitude
        : widget.to.longitude;

    double maxLongitude = widget.to.longitude > widget.from.longitude
        ? widget.to.longitude
        : widget.from.longitude;
    double maxLatitude = widget.to.latitude > widget.from.latitude
        ? widget.to.latitude
        : widget.from.latitude;
    LatLngBounds initialBounds = LatLngBounds(
        southwest: LatLng(minLatitude, minLongitude),
        northeast: LatLng(maxLatitude, maxLongitude));
    print("price per km ${widget.courier.data["price_per_kam"]}");
    FirebaseUser firebaseUser = Provider.of<FirebaseUser>(context);
    return Scaffold(
      key: scaffoldState,
      body: Stack(
        children: <Widget>[
          GoogleMap(
            polylines: widget.polylines,
            markers: widget.markers,
            initialCameraPosition: CameraPosition(target: widget.from),
            onMapCreated: (GoogleMapController mapController) {
              final cameraUpdate =
                  CameraUpdate.newLatLngBounds(initialBounds, 100);
              mapController.animateCamera(cameraUpdate);
            },
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: Card(
                margin: EdgeInsets.all(0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${widget.courier.data["name"]}",
                        style: Theme.of(context).textTheme.headline6,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.drive_eta,
                        size: 32,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text("\$${price.floor()}",
                          style: Theme.of(context).textTheme.bodyText1.copyWith(
                              fontWeight: FontWeight.w600, fontSize: 20)),
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
                                    .copyWith(
                                        color: Colors.white, fontSize: 16)),
                            onPressed: () {
                              final driverCollection = couriersCollection
                                  .document(widget.courier.documentID)
                                  .collection("drivers");
                              driverCollection
                                  .document(widget.driver.documentID)
                                  .updateData({
                                "status": "active",
                                "startLocation": GeoPoint(widget.from.latitude,
                                    widget.from.longitude),
                                "endLocation": GeoPoint(
                                    widget.to.latitude, widget.to.longitude)
                              }).then((_) {
                                scaffoldState.currentState
                                    .showSnackBar(SnackBar(
                                  content:
                                      Text("Your ride will arrive shortly"),
                                  action: SnackBarAction(
                                      label: "OK", onPressed: () {}),
                                ));
                                final rideRequest = couriersCollection
                                    .document(widget.courier.documentID)
                                    .collection("rideRequestStatus")
                                    .document(firebaseUser.uid);
                                rideRequest.setData(
                                    {"currentStatus": "in_progress", "userId": firebaseUser.uid});
                                firestore
                                    .collection("users")
                                    .document(firebaseUser.uid)
                                    .collection("ridehistory")
                                    .add({
                                  "currentStatus": "in_progress",
                                  "from": GeoPoint(
                                      widget.from.latitude, widget.to.longitude),
                                  "to": GeoPoint(widget.to.latitude, widget.to.longitude)
                                });
                              });
                            })),
                  ],
                ),
              ))
        ],
      ),
    );
  }
}
