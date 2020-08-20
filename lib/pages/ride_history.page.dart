import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RideHistory extends StatefulWidget {
  @override
  _RideHistoryState createState() => _RideHistoryState();
}

class _RideHistoryState extends State<RideHistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min,children: <Widget>[
      Text("You currently have no completed rides", style: Theme.of(context).textTheme.headline6),
      Text(":}")
    ])));
  }
}
