import 'package:chatsakki/controller/auth_controller.dart';
import 'package:chatsakki/login.dart';
import 'package:flutter/material.dart';
import 'package:chatsakki/intro_and_uthenticate/Screens/Signup/signup_screen.dart';
import 'package:chatsakki/intro_and_uthenticate/components/already_have_an_account_acheck.dart';
import 'package:chatsakki/intro_and_uthenticate/components/rounded_button.dart';
import 'package:chatsakki/intro_and_uthenticate/components/rounded_input_field.dart';
import 'package:chatsakki/intro_and_uthenticate/components/rounded_password_field.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Login/components/background.dart';

import 'dart:async';
import 'package:chatsakki/helperfunctions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../home.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../Signup/components/or_divider.dart';
import '../Signup/components/social_icon.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirebaseUser currentUser;
  TextEditingController emailEditingController = new TextEditingController();
  TextEditingController passwordEditingController = new TextEditingController();
  bool isLoading = false;
  bool isLoggedIn = false;

  @override
  void initState() {
    print("inside the login.drt");
    //for(String x in  xyz)
    //  print(xyz.toString());
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

  Future<Null> handleSignIn() async{
    try{
      FirebaseUser firebaseUser = await AuthController().signInWithEmailAndPassword(emailEditingController.text, passwordEditingController.text);
      print("firebase user is:.......$firebaseUser");
      if(firebaseUser != null){
        Fluttertoast.showToast(msg: "Sign in success");
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => HomeScreen(currentUserId: firebaseUser.uid)));
      } else {
        this.setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: "User doesn\'t exist");
      }
    }catch (e) {
      this.setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Sign in fail");
      print("error thrown in login page is :   ${e.toString()}");
    }
  }
  Future<Null> handleGoogleSignIn() async {
    //prefs = await SharedPreferences.getInstance();
    try {
      FirebaseUser firebaseUser = await AuthController().signInWithGoogle(context);
      print("firebase user using google sign in is:.......$firebaseUser");
      if(firebaseUser != null){
        Fluttertoast.showToast(msg: "Sign in success");
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => HomeScreen(currentUserId: firebaseUser.uid)));
      } else {
         this.setState(() {
           isLoading = false;
         });
        Fluttertoast.showToast(msg: "Sign in fail");
      }
    } catch (e) {
      this.setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Sign in fail");
      print("error thrown in login page is :   ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      //body: Body(),
      body: Background(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "LOGIN",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: size.height * 0.03),
              SvgPicture.asset(
                "assets/icons/login.svg",
                height: size.height * 0.35,
              ),
              SizedBox(height: size.height * 0.03),
              RoundedInputField(
                keyBoardType: TextInputType.emailAddress,
                hintText: "Your Email",
                onChanged: (value) {
                  emailEditingController.text = value;
                },
              ),
              RoundedPasswordField(
                onChanged: (value) {
                  passwordEditingController.text = value;
                },
              ),
              isLoading
                  ? Container(
                child: Center(child: CircularProgressIndicator()),
              ): RoundedButton(
                text: "LOGIN",
                press: (){
                  handleSignIn();
                  this.setState(() { isLoading = true;});
                },
              ),
              SizedBox(height: size.height * 0.03),
              AlreadyHaveAnAccountCheck(
                press: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return SignUpScreen();
                      },
                    ),
                  );
                },
              ),
              OrDivider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SocalIcon(
                    colors: Colors.indigo,
                    iconSrc: "assets/icons/facebook.svg",
                    press: () {},
                  ),
                  SocalIcon(
                    colors: Colors.blue,
                    iconSrc: "assets/icons/twitter.svg",
                    press: () {},
                  ),
                  SocalIcon(
                    colors: Colors.red,
                    iconSrc: "assets/icons/google-plus.svg",
                    press: (){
                      handleGoogleSignIn();
                      this.setState(() { isLoading = true;});
                    },//,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
