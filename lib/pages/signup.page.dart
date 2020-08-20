import 'package:drivingapp/main.dart';
import 'package:drivingapp/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  GoogleSignIn googleSignIn = GoogleSignIn();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _obscurePasswordText = false;
  Future<int> signInWithGoogle() async {
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
    await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
              child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text("First Time?",
                            style: Theme.of(context).textTheme.headline4.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w500)),
                        Text("Sign up here to continue ",
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(color: Colors.grey))
                      ],
                    )
                  ],
                ),
                SizedBox(height: 48),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      labelText: "Email",
                      labelStyle: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(color: Colors.indigo, fontSize: 15)),
                ),
                SizedBox(height: 32),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePasswordText,

                  decoration: InputDecoration(
                      labelText: "Password",
                      suffixIcon: IconButton(icon: Icon(_obscurePasswordText ? Icons.visibility: Icons.visibility_off), onPressed: () {
                        setState(() => {_obscurePasswordText = !_obscurePasswordText});
                      }),
                      labelStyle: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(color: Colors.indigo, fontSize: 15)),
                ),
                SizedBox(height: 48),
                ButtonTheme(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  minWidth: double.infinity,
                  child: RaisedButton(
                    elevation: 0,
                    onPressed: () {
                      handleEmailSignUp(emailController.text, passwordController.text).then((user) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                          return MultiProvider(providers: [
                            StreamProvider<FirebaseUser>.value(value: FirebaseAuth.instance.onAuthStateChanged),

                          ],

                          child: MyHomePage(),);
                        }));
                      }).catchError(() {});
                    },
                    child: Text(
                      "Sign Up",
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: _googleSignIn(context),
                ),
                _signInNavButton(context, prompt: "Already have an account? Sign in Instead")
              ],
            ),
          )),
        ),
      ),
    );
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
            return MyHomePage(title: "E Transit");
          })));
        },
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 20),
        label: Text(
          "Sign Up with Google",
          style: TextStyle(fontSize: 16),
        ));
  }
  FlatButton _signInNavButton(BuildContext context, {String prompt = "Don't have an account? Sign Up Instead."}) {
    return FlatButton(

        onPressed: () {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
            return LoginPage();
          }));
        },
        child: Text(prompt,
            style: Theme.of(context).textTheme.button.copyWith(
              fontSize: 12,
            )));
  }

  Future<FirebaseUser> handleEmailSignUp(String email, String password) async {
    AuthResult authResult = await this.auth.createUserWithEmailAndPassword(email: email, password: password);
    if(authResult.user == null)
      throw NullThrownError();
    print("sign up with email succeeded: ${authResult.user}");
    return authResult.user;
  }
}
