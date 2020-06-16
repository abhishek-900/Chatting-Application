import 'package:chatsakki/intro_and_uthenticate/Screens/Welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'const.dart';
import 'helperfunctions.dart';
import 'home.dart';

void main(){
  WidgetsFlutterBinding.ensureInitialized();
  getLoggedInState();
}
getLoggedInState() async {
  String id;
  bool userIsLoggedIn = await HelperFunctions.getUserLoggedInSharedPreference();
  id = await HelperFunctions.getUserIdSharedPreference();
  print("main mein hu id ayi h..................... $id and $userIsLoggedIn");

  if (userIsLoggedIn != null) {
    if (id != null)
      runApp(MaterialApp(
          theme: ThemeData(
            primaryColor: themeColor,
          ),
        debugShowCheckedModeBanner: false,
        home: HomeScreen(currentUserId: id)),
      );
    else
      runApp(MaterialApp(
          theme: ThemeData(
            primaryColor: themeColor,
          ),
          debugShowCheckedModeBanner: false,
          home: WelcomeScreen(),//LoginScreen(title: 'CHAT DEMO'),
      ));
  }else{
    runApp(MaterialApp(
      theme: ThemeData(
        primaryColor: themeColor,
      ),
      debugShowCheckedModeBanner: false,
      home: Container(
        child: Center(
          child: WelcomeScreen(),//LoginScreen(title: 'CHAT DEMO'),
        ),
      ),
    ),);
  }
}

/*
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool userIsLoggedIn;
  String id;

  */
/*getLoggedInState() async {
    await HelperFunctions.getUserLoggedInSharedPreference().then((value){
      setState(() {
        userIsLoggedIn  = value;
      });
    });
    id = await HelperFunctions.getUserIdSharedPreference();
    print("main mein hu id ayi h..................... $id nd $userIsLoggedIn");
  }*//*


  @override
  void initState() {
    print("is it init??");
    // TODO: implement initState
   // getLoggedInState();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    print("is it build??");
    return MaterialApp(
      title: 'Chat Demo',
      theme: ThemeData(
        primaryColor: themeColor,
      ),
      home: userIsLoggedIn != null ?userIsLoggedIn ?  HomeScreen(currentUserId: id) :LoginScreen(title: 'CHAT DEMO'),
      : Container(
        child: Center(
          child: LoginScreen(title: 'CHAT DEMO'),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
*/
