import 'package:drivingapp/main.dart';
import 'package:drivingapp/pages/signup.page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  GoogleSignIn googleSignIn = GoogleSignIn();
  TextEditingController passwordController = new TextEditingController();
  TextEditingController emailController = new TextEditingController();
  Future<int> signInWithGoogle() async {
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final AuthResult authResult = await auth.signInWithCredential(credential);
    final FirebaseUser user = authResult.user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await auth.currentUser();
    assert(user.uid == currentUser.uid);

    return 200;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24, top: 56),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(width: 120, height: 120,child: Image(image: AssetImage('assets/logo.jpg'),)),
              Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("Welcome Back,",
                          style: Theme.of(context).textTheme.headline4.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w400)),
                      Text("Sign in to Continue",
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              .copyWith(color: Colors.grey))
                    ],
                  )
                ],
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: Theme.of(context).textTheme.bodyText1.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryColor)),
              ),
              SizedBox(height: 40),
              TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).primaryColor))),
              SizedBox(height: 32),
              ButtonTheme(
                padding: EdgeInsets.symmetric(vertical: 16),
                buttonColor: Theme.of(context).primaryColor,
                child: RaisedButton(
                  elevation: 0,
                  onPressed: () async {
                    if(emailController.text == null || passwordController.text == null)
                      return;
                    print(emailController.text);
                    _signInWithEmailAndPassword(emailController.text, passwordController.text);

                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Text(
                    "Sign In",
                    style: Theme.of(context)
                        .textTheme
                        .bodyText1
                        .copyWith(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 16),
                child: _googleSignIn(context),
              ),
              _signUpNavButton(context)
            ],
          ),
        ),
      )),
    );
  }

  FlatButton _signUpNavButton(BuildContext context) {
    return FlatButton(
        onPressed: () {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
            return SignupPage();
          }));
        },
        child: Text("Don't have an account? Sign Up Instead.",
            style: Theme.of(context).textTheme.button.copyWith(
                  fontSize: 12,
                )));
  }

  Widget _googleSignIn(BuildContext context) {
    return OutlineButton.icon(
        icon: Container(
            height: 32,
            width: 32,
            child: Image(image: AssetImage('assets/google_icon.png'))),
        splashColor: Colors.grey,
        onPressed: () {
          signInWithGoogle().whenComplete(() => Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(builder: (context) {
                return MultiProvider(
                  providers: [
                    StreamProvider<FirebaseUser>.value(value: FirebaseAuth.instance.onAuthStateChanged)
                  ],

                  child:
                     MyHomePage(title: "E Transit")

                );
              })));
        },
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        label: Text(
          "Sign in with Google",
          style: TextStyle(fontSize: 16),
        ));
  }

  Future<FirebaseUser> _signInWithEmailAndPassword(String email, String password) async {
    print(email);
  await this.auth.signInWithEmailAndPassword(email: email.trim(), password: password).then((authResult) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
        return MultiProvider(providers: [
          StreamProvider<FirebaseUser>.value(value: FirebaseAuth.instance.onAuthStateChanged,)
        ],
        child: MyHomePage(),
        );
      }));
    });

  }

}
