import 'package:chatsakki/controller/auth_controller.dart';
import 'package:chatsakki/intro_and_uthenticate/Screens/Login/login_screen.dart';
import 'package:chatsakki/intro_and_uthenticate/components/already_have_an_account_acheck.dart';
import 'package:chatsakki/intro_and_uthenticate/components/rounded_button.dart';
import 'package:chatsakki/intro_and_uthenticate/components/rounded_input_field.dart';
import 'package:chatsakki/intro_and_uthenticate/components/rounded_password_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../home.dart';
import '../Signup/components/background.dart';

class SignUpScreen extends StatefulWidget {

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController passwordEditingController = TextEditingController();
  TextEditingController usernameEditingController = TextEditingController();
  bool isLoading;

  handleSignUp() async{
    try{
      FirebaseUser user = await AuthController().signUpWithEmailAndPassword(emailEditingController.text, passwordEditingController.text, usernameEditingController.text);
      if(user != null){
        Fluttertoast.showToast(msg: "Sign up successful");
        Navigator.push(context, MaterialPageRoute(
            builder: (context) => HomeScreen(currentUserId: user.uid,)));
      }else {
        this.setState(() {
          isLoading = false;
        });
        Fluttertoast.showToast(msg: "Sign up failed!");
      }
    }on PlatformException catch(e){
      this.setState(() {
        isLoading = false;
      });

      if(e.code == "ERROR_EMAIL_ALREADY_IN_USE")
      Fluttertoast.showToast(msg: "User already exists");
      else
        Fluttertoast.showToast(msg: "Sign up failed");
      print("error thrown in signup page is :   ${e.code}");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    isLoading = false;
    super.initState();
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
                "SIGNUP",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: size.height * 0.03),
              SvgPicture.asset(
                "assets/icons/signup.svg",
                height: size.height * 0.35,
              ),
              RoundedInputField(
                hintText: "Nickname",
                keyBoardType: TextInputType.text,
                onChanged: (value) {
                  usernameEditingController.text = value;
                },
              ),
              RoundedInputField(
                hintText: "Your Email",
                keyBoardType: TextInputType.emailAddress,
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
                text: "SIGNUP",
                press: () {
                  handleSignUp();
                  this.setState(() {
                    isLoading = true;
                  });
                },
              ),
              SizedBox(height: size.height * 0.03),
              AlreadyHaveAnAccountCheck(
                login: false,
                press: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return LoginScreen();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
