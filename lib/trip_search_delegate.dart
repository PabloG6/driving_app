import 'package:drivingapp/states/trip_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class TripSearchDelegate extends StatefulWidget {
  TripSearchDelegate();

  @override
  _TripSearchDelegateState createState() => _TripSearchDelegateState();


}

class _TripSearchDelegateState extends State<TripSearchDelegate> {
  @override
  Widget build(BuildContext context) {
    TripState state = Provider.of<TripState>(context);
    return Container(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8.0, 2, 8, 4),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  onChanged: (String query) {
                    state.makePlaceRequest(query);
                  },
                  decoration: InputDecoration(
                    labelText: "Pickup",
                    contentPadding: EdgeInsets.only(
                        left: ScreenUtil().setWidth(12),
                        top: ScreenUtil().setHeight(8),
                        right: ScreenUtil().setWidth(12),
                        bottom: ScreenUtil().setHeight(12)),
                    hintText: "Pickup",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                      hintText: "Dropoff",
                      labelText: "Dropoff",
                      contentPadding: EdgeInsets.only(
                          left: ScreenUtil().setWidth(12),
                          top: ScreenUtil().setHeight(8),
                          right: ScreenUtil().setWidth(12),
                          bottom: ScreenUtil().setHeight(12)),
                      border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
        ),
        decoration: BoxDecoration(color: Colors.white, boxShadow: <BoxShadow>[
          BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 4,
              spreadRadius: 2,
              color: Colors.grey.shade400),
        ]));
  }
}
