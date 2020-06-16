import 'dart:async';

import 'package:chatsakki/helperfunctions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'const.dart';
import 'home.dart';
import 'widget/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
 // SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  FirebaseUser currentUser;

  @override
  void initState() {
    print("inside the login.drt");
    super.initState();
    isSignedIn();
  }

  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    //prefs = await SharedPreferences.getInstance();
    String id = await HelperFunctions.getUserIdSharedPreference();
    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      //print(" My Shared preference id after signing in is :   ${prefs.getString('id')}");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(currentUserId: id)),
      );
    }

    this.setState(() {
      isLoading = false;
    });
  }

  Future<Null> handleSignIn() async {
    //prefs = await SharedPreferences.getInstance();

    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    print("credentils : ${googleAuth.accessToken} and ${googleAuth.idToken} ");
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,

    );


    try {
      FirebaseUser firebaseUser = (await firebaseAuth.signInWithCredential(
          credential)).user;
      if (firebaseUser != null) {
        // Check is already sign up
        final QuerySnapshot result =
        await Firestore.instance.collection('users').where(
            'id', isEqualTo: firebaseUser.uid).getDocuments();
        final List<DocumentSnapshot> documents = result.documents;
        if (documents.length == 0) {
          // Update data to server if new user
          Firestore.instance.collection('users')
              .document(firebaseUser.uid)
              .setData({
            'email': firebaseUser.email,
            'nickname': firebaseUser.displayName,
            'photoUrl': firebaseUser.photoUrl,
            'id': firebaseUser.uid,
            'createdAt': DateTime
                .now()
                .millisecondsSinceEpoch
                .toString(),
            'chattingWith': null,
            'connectionStatus' : 'Online'
          });

          // Write data to local
          currentUser = firebaseUser;
          await HelperFunctions.saveUserEmailSharedPreference(currentUser.email);//prefs.setString('id', currentUser.uid);
          await HelperFunctions.saveUserIdSharedPreference(currentUser.uid);//prefs.setString('id', currentUser.uid);
          await HelperFunctions.saveUserNameSharedPreference(currentUser.displayName);//prefs.setString('nickname', currentUser.displayName);
          await HelperFunctions.saveUserPhotoUrlSharedPreference(currentUser.photoUrl);//prefs.setString('photoUrl', currentUser.photoUrl);
        } else {
          // Write data to local
          await HelperFunctions.saveUserEmailSharedPreference(documents[0]['email']);//prefs.setString('id', currentUser.uid);
          await HelperFunctions.saveUserIdSharedPreference(documents[0]['id']);//prefs.setString('id', currentUser.uid);
          await HelperFunctions.saveUserNameSharedPreference(documents[0]['nickname']);//prefs.setString('nickname', currentUser.displayName);
          await HelperFunctions.saveUserPhotoUrlSharedPreference(documents[0]['photoUrl']);//prefs.setString('photoUrl', currentUser.photoUrl);
          await HelperFunctions.saveUserAboutMeSharedPreference(documents[0]['aboutMe']);
        }

        Fluttertoast.showToast(msg: "Sign in success");
        this.setState(() {
          isLoading = false;
        });

        Navigator.push(context, MaterialPageRoute(
            builder: (context) => HomeScreen(currentUserId: firebaseUser.uid)));
      } else {
        Fluttertoast.showToast(msg: "Sign in fail");
        this.setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Sign in fail");
      print("error thrown in login page is :   ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: <Widget>[
            Center(
              child: FlatButton(
                  onPressed: handleSignIn,
                  child: Text(
                    'SIGN IN WITH GOOGLE',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  color: Color(0xffdd4b39),
                  highlightColor: Color(0xffff7f7f),
                  splashColor: Colors.transparent,
                  textColor: Colors.white,
                  padding: EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0)),
            ),

            // Loading
            Positioned(
              child: isLoading ? const Loading() : Container(),
            ),
          ],
        ));
  }
}
