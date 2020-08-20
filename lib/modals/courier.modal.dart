import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:drivingapp/pages/confirm_ride.page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class CourierModal extends StatefulWidget {
  final LatLng startLocation;
  final LatLng endLocation;
  final Set polylines;
  final Set markers;
  final double distance;
  CourierModal({this.startLocation, this.endLocation, this.polylines, this.markers, this.distance
  });

  @override
  _CourierModalState createState() => _CourierModalState();
}

class _CourierModalState extends State<CourierModal> {
  final firestore = Firestore.instance;
  CollectionReference couriersCollection;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    couriersCollection = firestore.collection('couriers');
  }

  @override
  Widget build(BuildContext context) {
    FirebaseUser user = Provider.of<FirebaseUser>(context);
    return Container(
      width: double.infinity,
      height: 280,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text("Couriers", style: Theme
                .of(context)
                .textTheme
                .headline6),
            StreamBuilder<QuerySnapshot>(
              stream: couriersCollection.snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return Text(
                        "No couriers currently available, try again later",
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyText1);
                  case ConnectionState.done:
                    if (snapshot.hasData) {
                      return ListView.builder(
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            if (snapshot.hasData) {
                              return ListView.separated(
                                  separatorBuilder: (context, index) =>
                                      Divider(
                                        thickness: 2,
                                      ),
                                  itemCount: snapshot.data?.documents?.length,
                                  itemBuilder: (context, index) {
                                    final datum =
                                        snapshot.data?.documents[index].data;
                                    return ListTile(
                                      onTap: () {
                                        print("tapped");
                                        couriersCollection
                                            .document(snapshot?.data
                                            ?.documents[index]?.documentID)
                                            .collection("rideRequest")
                                            .add({
                                          "startLocation": widget.startLocation,
                                          "endLocation": widget.endLocation
                                        }).then((document) {
                                          print("ended adding start location");
                                        });
                                      },
                                      title: Text("${datum["name"]}",
                                          style: Theme
                                              .of(context)
                                              .textTheme
                                              .headline6),
                                      trailing: Icon(Icons.chevron_right),
                                    );
                                  });
                            }
                            return Text(
                                "No couriers curretly available, try again later",
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .bodyText1);
                          });
                    }
                    return Text(
                        "No couriers currently available, try again later",
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyText1);
                    break;

                  case ConnectionState.active:
                    if (snapshot.hasData) {
                      return ListView.builder(
                          shrinkWrap: true,
                          itemCount: snapshot.data?.documents?.length,
                          itemBuilder: (context, index) {
                            final datum = snapshot.data?.documents[index].data;
                            return ListTile(
                              onTap: () async {

                                final courier = snapshot?.data
                                    ?.documents[index];
                                final drivers = await couriersCollection
                                    .document(courier.documentID)
                                    .collection("drivers")
                                    .where("status", isEqualTo: "idle")
                                    .getDocuments();

                                if (drivers?.documents?.length > 0) {
                                  final driver = drivers.documents.first;
                                  Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (context) {
                                        return MultiProvider(
                                          providers: [
                                            StreamProvider<FirebaseUser>.value(value: FirebaseAuth.instance.onAuthStateChanged),
                                          ],
                                          child: ConfirmRidePage(
                                              polylines: widget.polylines,
                                              markers: widget.markers,
                                              from: widget.startLocation,
                                              to: widget.endLocation,
                                              driver: driver,
                                              distance: widget.distance,
                                              courier: courier),
                                        );
                                      }));

                                }
                                else {
                                  showDialog<void>(context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(content: Text("There's currently no available drivers, try again later."), actions: <Widget>[
                                          FlatButton(child: Text("Done"), onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).pop();
                                          }),

                                        ]);
                                      });
                                }
                              },
                              title: Text("${datum["name"]}",
                                  style: Theme
                                      .of(context)
                                      .textTheme
                                      .headline6),
                              trailing: Icon(Icons.chevron_right),
                            );
                          });
                    }
                    return Text(
                        "No couriers currently available, try again later",
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyText1);
                  case ConnectionState.waiting:
                    return CircularProgressIndicator();
                  default:
                    return Text("Hello World");
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}


