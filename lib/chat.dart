import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatsakki/controller/auth_controller.dart';
import 'package:chatsakki/helperfunctions.dart';
import 'package:chatsakki/intro_and_uthenticate/constants.dart';
import 'package:chatsakki/widget/curve_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'const.dart';
import 'widget/full_photo.dart';
import 'widget/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class Chat extends StatelessWidget {
  final String peerId;
  final String peerAvatar;
  String connectionStatus;
  final String userName;

  Chat(
      {Key key,
      @required this.peerId,
      @required this.peerAvatar,
      /*@required this.connectionStatus,*/ @required this.userName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 9.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.videocam),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => null));
              }),
        ],
        title: Row(
          children: <Widget>[
            Material(
              child: peerAvatar != null
                  ? CachedNetworkImage(
                      /*placeholder: (context, url) => Container(
                  child: CircularProgressIndicator(
                    strokeWidth: 1.0,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                  width: 50.0,
                  height: 50.0,
                  padding: EdgeInsets.all(15.0),
                ),*/
                      imageUrl: peerAvatar,
                      width: 40.0,
                      height: 40.0,
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      Icons.account_circle,
                      size: 50.0,
                      color: greyColor,
                    ),
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              clipBehavior: Clip.hardEdge,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder(
                  stream: AuthController().getConnectionStatus(peerId: peerId),
                  builder: (context, snapshot) {
                    print(snapshot.data.toString());
                    if (snapshot.data == null || snapshot == null) {
                      return Text(
                        userName,
                        style: TextStyle(
                            color: primaryColor, fontWeight: FontWeight.bold),
                      );
                    } else {
                      DocumentSnapshot ref = snapshot.data;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            userName,
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold),
                          ),
                          if (ref.data["connectionStatus"] != null)
                            Text(
                              ref.data["connectionStatus"],
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14.0),
                            ),
                        ],
                      );
                    }
                  }),
            ),
          ],
        ),
        // centerTitle: true,
      ),
      body: ChatScreen(
        peerId: peerId,
        peerAvatar: peerAvatar,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerAvatar;

  ChatScreen({Key key, @required this.peerId, @required this.peerAvatar})
      : super(key: key);

  @override
  State createState() =>
      ChatScreenState(peerId: peerId, peerAvatar: peerAvatar);
}

class ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  ChatScreenState({Key key, @required this.peerId, @required this.peerAvatar});

  String peerId;
  String peerAvatar;
  String id;

  var listMessage;
  String groupChatId;

  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    print("init of cht.drt");
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    focusNode.addListener(onFocusChange);
    groupChatId = '';
    isLoading = false;
    isShowSticker = false;
    imageUrl = '';
    readLocal();
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  readLocal() async {
    //prefs = await SharedPreferences.getInstance();
    id = await HelperFunctions
        .getUserIdSharedPreference(); //prefs.getString('id') ?? '';
    if (id.hashCode <= peerId.hashCode) {
      groupChatId = '$id-$peerId';
    } else {
      groupChatId = '$peerId-$id';
    }
    Firestore.instance
        .collection('users')
        .document(id)
        .updateData({'chattingWith': peerId});
    setState(() {});
  }

  Future getImage() async {
    PickedFile imgFile =
        await ImagePicker().getImage(source: ImageSource.gallery);
    setState(() {
      imageFile = File(imgFile.path != null ? imgFile.path : '');
    });

    if (imageFile.existsSync()) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  void onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .document(DateTime.now().millisecondsSinceEpoch.toString());

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
            'type': type
          },
        );
      });
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    var mq = MediaQuery.of(context).size;
    if (document['idFrom'] == id) {
      // Right (my message)
      return Row(
        children: <Widget>[
          document['type'] == 0
              // Text
              ? Container(
                  child: Column(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          document['content'],
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          child: Text(
                            DateFormat('dd MMM kk:mm').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                    int.parse(document['timestamp']))),
                            style: TextStyle(
                                color: greyColor,
                                fontSize: 12.0,
                                fontStyle: FontStyle.italic),
                          ),
                          margin: EdgeInsets.only( top: 5.0,),
                        ),
                      )
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: mq.width/2,
                  decoration: BoxDecoration(
                      /*gradient: LinearGradient(
                        colors: [Colors.deepPurpleAccent.withOpacity(0.5),Colors.deepPurpleAccent ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter
                      ),*/
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                      color: Colors.deepPurpleAccent.withOpacity(0.8),//Colors.deepPurple
                      boxShadow: [
                        BoxShadow(
                            blurRadius: 20.0,
                            offset: Offset(10, 10),
                            color: Colors.black54)
                      ]),
                  margin: EdgeInsets.only(
                      bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                      right: 10.0),
                )
              : document['type'] == 1
                  // Image
                  ? Container(
            padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          FlatButton(
                            padding: EdgeInsets.all(0.0),
                            child: Material(
                              child: CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                  child: CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(themeColor),
                                  ),
                                  width: 200.0,
                                  height: 200.0,
                                  padding: EdgeInsets.all(70.0),
                                  decoration: BoxDecoration(
                                    color: greyColor2,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8.0),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Material(
                                  child: Image.asset(
                                    'assets/images/img_not_available.jpeg',
                                    width: 200.0,
                                    height: 200.0,
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8.0),
                                  ),
                                  clipBehavior: Clip.hardEdge,
                                ),
                                imageUrl: document['content'],
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          FullPhoto(url: document['content'])));
                            },
                            //padding: EdgeInsets.all(8),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              child: Text(
                                DateFormat('dd MMM kk:mm').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.parse(document['timestamp']))),
                                style: TextStyle(
                                    color: greyColor,
                                    fontSize: 12.0,
                                    fontStyle: FontStyle.italic),
                              ),
                              margin: EdgeInsets.only(top: 5.0,bottom: 5.0),
                            ),
                          ),
                        ],
                      ),
                      margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                          right: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                        color: Colors.deepPurpleAccent.withOpacity(0.8),//Colors.deepPurple
                      ),
                    )
                  // Sticker
                  : Container(
                      child: Image.asset(
                        'assets/images/${document['content']}.gif',
                        width: 100.0,
                        height: 100.0,
                        fit: BoxFit.cover,
                      ),
                      margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                          right: 10.0),
                    ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      return Container(
        child: Row(
          children: <Widget>[
            isLastMessageLeft(index)
                ? Material(
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Container(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.0,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                        width: 35.0,
                        height: 35.0,
                        padding: EdgeInsets.all(10.0),
                      ),
                      imageUrl: peerAvatar,
                      width: 35.0,
                      height: 35.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(18.0),
                    ),
                    clipBehavior: Clip.hardEdge,
                  )
                : Container(width: 35.0),
            document['type'] == 0
                ? Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          document['content'],
                          style: TextStyle(color: Colors.white),
                        ),
                        //isLastMessageLeft(index)
                             Container(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              DateFormat('dd MMM kk:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(document['timestamp']))),
                              style: TextStyle(
                                  color: greyColor,
                                  fontSize: 12.0,
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                          margin: EdgeInsets.only( top: 5.0,),
                        )
                            //: Container()
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                    width: mq.width/2,
                    decoration: BoxDecoration(
                        /*gradient: LinearGradient(
                          colors: [Color(0xff8a2be2).withOpacity(0.5), Color(0xff8A2BE2)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),*/
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        color: Colors.deepPurple.withOpacity(0.8),
                        ///*Color(0xffA67CFA),Color(0xff4AAEA4),*/Color(0xff52C7B0),
                        boxShadow: [
                          BoxShadow(
                              blurRadius: 20.0,
                              offset: Offset(10, 10),
                              color: Colors.black54),
                        ]),
                    margin: EdgeInsets.only(
                        bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                        right: 10.0, left: 5.0),
                  )
                : document['type'] == 1
                    ? Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            FlatButton(
                              child: Material(
                                child: CachedNetworkImage(
                                  placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          themeColor),
                                    ),
                                    width: 200.0,
                                    height: 200.0,
                                    padding: EdgeInsets.all(70.0),
                                    decoration: BoxDecoration(
                                      color: greyColor2,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Material(
                                    child: Image.asset(
                                      'assets/images/img_not_available.jpeg',
                                      width: 200.0,
                                      height: 200.0,
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8.0),
                                    ),
                                    clipBehavior: Clip.hardEdge,
                                  ),
                                  imageUrl: document['content'],
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8.0)),
                                clipBehavior: Clip.hardEdge,
                              ),
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => FullPhoto(
                                            url: document['content'])));
                              },
                              padding: EdgeInsets.all(8),
                            ),
                            /*isLastMessageLeft(index)
                                ?*/ Container(
                              child: Text(
                                DateFormat('dd MMM kk:mm').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.parse(document['timestamp']))),
                                style: TextStyle(
                                    color: greyColor,
                                    fontSize: 12.0,
                                    fontStyle: FontStyle.italic),
                              ),
                              margin: EdgeInsets.only(right: 15, top: 2.0,bottom: 5.0),
                            )
                          ],
                        ),
                        margin: EdgeInsets.only(left: 10.0),
                        decoration: BoxDecoration(
                          /*gradient: LinearGradient(
                            colors: [kPrimaryLightColor.withOpacity(0.5), kPrimaryLightColor],
                          begin: Alignment.topCenter,
                          ),*/
                          color: Colors.deepPurple.withOpacity(0.8),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                          ),
                          //color: kPrimaryLightColor.withOpacity(0.5),
                        ),
                      )
                    : Container(
                        child: Image.asset(
                          'assets/images/${document['content']}.gif',
                          width: 100.0,
                          height: 100.0,
                          fit: BoxFit.cover,
                        ),
                        margin: EdgeInsets.only(
                            bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                            right: 10.0),
                      ),
          ],
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] == id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] != id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      Firestore.instance
          .collection('users')
          .document(id)
          .updateData({'chattingWith': null});
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // List of messages
              buildListMessage(),
              // Sticker
              (isShowSticker ? buildSticker() : Container()),
              // Input content
              buildInput(),
            ],
          ),
          // Loading
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi1', 2),
                child: Image.asset(
                  'assets/images/mimi1.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi2', 2),
                child: Image.asset(
                  'assets/images/mimi2.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi3', 2),
                child: Image.asset(
                  'assets/images/mimi3.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi4', 2),
                child: Image.asset(
                  'assets/images/mimi4.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi5', 2),
                child: Image.asset(
                  'assets/images/mimi5.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi6', 2),
                child: Image.asset(
                  'assets/images/mimi6.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => onSendMessage('mimi7', 2),
                child: Image.asset(
                  'assets/images/mimi7.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi8', 2),
                child: Image.asset(
                  'assets/images/mimi8.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
              FlatButton(
                onPressed: () => onSendMessage('mimi9', 2),
                child: Image.asset(
                  'assets/images/mimi9.gif',
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: greyColor2, width: 0.5)),
          color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading ? const Loading() : Container(),
    );
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                  icon: Icon(Icons.perm_media),
                  onPressed: showBtmSheet)
            ),
            color: Colors.white,
          ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: primaryColor, fontSize: 15.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: greyColor),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => onSendMessage(textEditingController.text, 0),
                color: primaryColor,
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: greyColor2, width: 0.5)),
          color: Colors.white),
    );
  }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          : StreamBuilder(
              stream: Firestore.instance
                  .collection('messages')
                  .document(groupChatId)
                  .collection(groupChatId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) =>
                        buildItem(index, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }

  void showBtmSheet() {
    showModalBottomSheet(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
        ),
        context: (context), builder: (context){
      return Container(
        height: 100,
        child: Row(
          children: <Widget>[
            Material(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1.0),
                child: IconButton(
                  icon: Icon(Icons.image),
                  onPressed: getImage,
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),
            Material(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1.0),
                child: IconButton(
                  icon: Icon(Icons.face),
                  onPressed: getSticker,
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),
            Material(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1.0),
                child: IconButton(
                  icon: Icon(Icons.audiotrack),
                  onPressed: (){},
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),
            Material(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1.0),
                child: IconButton(
                  icon: Icon(Icons.contacts),
                  onPressed: getSticker,
                  color: primaryColor,
                ),
              ),
              color: Colors.white,
            ),
          ],
        ),
      );
    });
  }
}
