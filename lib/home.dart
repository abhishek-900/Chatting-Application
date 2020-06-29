import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatsakki/controller/auth_controller.dart';
import 'package:chatsakki/widget/curve_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat.dart';
import 'const.dart';
import 'intro_and_uthenticate/Screens/Welcome/welcome_screen.dart';
import 'settings.dart';
import 'widget/loading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserId;

  HomeScreen({Key key, @required this.currentUserId}) : super(key: key);

  @override
  State createState() => HomeScreenState(currentUserId: currentUserId);
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  HomeScreenState({Key key, @required this.currentUserId});
  String connectionStatus;
  final String currentUserId;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  //final GoogleSignIn googleSignIn = GoogleSignIn();
  List<String> chtIds = [];
  List<String> timeIds = [];
  String person;
  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("now in the home screen pge with id : ${widget.currentUserId}");
    gettingTime();
    registerNotification();
    configLocalNotification();
    getLists();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    //print(" checking status :- :- :-     $state");
    if (state == AppLifecycleState.resumed) {
      connectionStatus = 'Online';
    } else {
      connectionStatus = 'Offline';
    }
    Firestore.instance
        .collection('users')
        .document(widget.currentUserId)
        .updateData({'connectionStatus': connectionStatus});
    if (this.mounted) setState(() {});
  }

  void gettingTime() async {
    print("now printing users snpssss");

    await Firestore.instance.collection('users').snapshots().forEach((element) {
      List<DocumentSnapshot> liss = element.documents;
      for (DocumentSnapshot dd in liss) {
        if (dd.documentID != widget.currentUserId)
          chtIds.add(
              '${widget.currentUserId.toString()}-${dd.documentID.toString()}');
        else
          person = dd.data['nickname'];
        print(person);
      }
    });
  }

  void getLists() async {
    print("getting lists....");
    //for(String groupIds in chtIds){
    print("iss id mein... ");
    await Firestore.instance
        .collection('messages')
        .snapshots()
        .forEach((element) {
      List<DocumentSnapshot> liss = element.documents;
      for (DocumentSnapshot v in liss) {
        print("times hhhh ${v.documentID}");
        timeIds.add(v.documentID.toString());
      }
    });
    /*document(groupIds).collection(groupIds)
          .orderBy('timestamp', descending: true).snapshots().forEach((element) {
            print("time elements is...$element");

          print("dds re.....${liss[0].documentID.toString()}");
         */ /*timeIds.add(
                '${liss[0].documentID.toString()}');*/
    // });
    //}
  }

  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();
    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      Platform.isAndroid
          ? showNotification(message['notification'])
          : showNotification(message['aps']['alert']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      Firestore.instance
          .collection('users')
          .document(currentUserId)
          .updateData({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void configLocalNotification() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void onItemMenuPress(Choice choice) {
    switch (choice.title) {
      case 'Log out':
        handleSignOut();
        break;
      case 'Settings':
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Settings()));
        break;
    }
  }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid ? 'com.food.chatsakki' : null,
      'Flutter chat demo',
      'your channel description',
      playSound: true,
      icon: 'images/app_icon.png',
      enableLights: true,
      channelShowBadge: true,
      visibility: NotificationVisibility.Public,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
      ongoing: true,
    );
    var iOSPlatformChannelSpecifics =
        new IOSNotificationDetails(presentAlert: true, presentSound: true);
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    print("Notification messge is this:     $message");
    print(message['body'].toString());
    print(json.encode(message));

    await flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
        message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));
  }

  void _navigateToItemDetail(Map<String, dynamic> message) {
    final String pagechooser = message['status'];
    Navigator.pushNamed(context, pagechooser);
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });
    /*await FirebaseAuth.instance.signOut();
    //  await googleSignIn.disconnect();
      await GoogleSignIn().signOut();
*/
    await AuthController().signOut();

    this.setState(() {
      isLoading = false;
    });
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
        (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    print("cht ids to dekhlo...${chtIds}");
    print("time ids to dekhlo...${timeIds} ${timeIds.length}");
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MAIN',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          PopupMenuButton<Choice>(
            onSelected: onItemMenuPress,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                    value: choice,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          choice.icon,
                          color: primaryColor,
                        ),
                        Container(
                          width: 10.0,
                        ),
                        Text(
                          choice.title,
                          style: TextStyle(color: primaryColor),
                        ),
                      ],
                    ));
              }).toList();
            },
          ),
        ],
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            // List
            Container(
              child: StreamBuilder(
                stream: Firestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: Text(
                            'No Contacts',
                            textScaleFactor: 1.3,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) =>
                          buildItem(context, snapshot, index),
                      itemCount: snapshot.data.documents.length,
                      shrinkWrap: true,
                    );
                  }
                },
              ),
            ),
            // Loading
            Positioned(
              child: isLoading ? const Loading() : Container(),
            )
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }

  Widget buildItem(BuildContext context, AsyncSnapshot snapshotUser, index) {
    DocumentSnapshot document = snapshotUser.data.documents[index];
    String chatId = currentUserId.toString() + "-" + document['id'].toString();
    return StreamBuilder(
        stream: Firestore.instance
            .collection('messages')
            .document(chatId)
            .collection(chatId)
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && !snapshot.hasError) {
            if (document['id'] == currentUserId) {
              return Container();
            } else {
              String message = "";
              String talkingTo = person;
              dynamic dtum = snapshot.data;
              String lastDate = "";
              List<DocumentSnapshot> listMessage = dtum.documents;
              for (DocumentSnapshot d in listMessage) {
                if (d.data['idFrom'].toString() != currentUserId)
                  talkingTo =
                      document['nickname'].toString().split(" ").elementAt(0);
                else
                  talkingTo = person.toString().split(" ").elementAt(0);
                if (d.data['type'].toString() == '0')
                  message = talkingTo + ": " + d.data['content'].toString();
                else if (d.data['type'].toString() == '1')
                  message = '$talkingTo: Photo';
                else
                  message = '';
                lastDate = DateFormat.jm().format(
                    DateTime.fromMillisecondsSinceEpoch(
                        int.parse(d.data['timestamp'])));
              }
              return InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Chat(
                                peerId: document.documentID,
                                peerAvatar: document['photoUrl'],
                                //connectionStatus: document['connectionStatus'],
                                userName: document['nickname'],
                              )));
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: document['photoUrl'] != null
                            ? CachedNetworkImage(
                                imageUrl: document['photoUrl'],
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  width: 55.0,
                                  height: 55.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                        image: imageProvider, fit: BoxFit.fill),
                                  ),
                                ),
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                              )
                            : Icon(
                                Icons.account_circle,
                                size: 60.0,
                                color: greyColor,
                              ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              '${document['nickname'][0].toUpperCase()}${document['nickname'].substring(1)}',
                              textScaleFactor: 1.2,
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              lastDate,
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Text(
                            message,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      Divider(
                        thickness: 1.2,
                        height: 5,
                        indent: 80,
                      )
                    ],
                  ),
                ),
              );
            }
          } else
            return Container();
        });
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
