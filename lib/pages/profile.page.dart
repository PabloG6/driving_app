import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePagState createState() => _ProfilePagState();
}

class _ProfilePagState extends State<ProfilePage> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = new TextEditingController();
  @override
  Widget build(BuildContext context) {
    FirebaseUser user = Provider.of<FirebaseUser>(context);
    String initial = user.email[0].toUpperCase();

    print("${user.email} ======> email");
    _emailController.text = user.email;
    _passwordController.text = "someword";
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(),
            body: Container(
      width: double.infinity,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 18),
              child: CircleAvatar(
                  radius: 40,
                  child: Text(
                    "$initial",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(fontSize: 20, color: Colors.white),
                  )),
            ),
            Text("${user?.email}",
                style: Theme.of(context).textTheme.subtitle1.copyWith(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            Card(
              margin: EdgeInsets.all(6),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
              children: [
                  TextFormField(
                      controller: _emailController,
                      enabled: false,
                      decoration: InputDecoration(border: UnderlineInputBorder(), labelText: "Email", )),
                TextFormField(
                    controller: _passwordController,
                    enabled: false,
                    obscureText: true,
                    decoration: InputDecoration(border: UnderlineInputBorder(), labelText: "Password", )),

              ],
            ),
                ))
          ]),
    )));
  }
}
