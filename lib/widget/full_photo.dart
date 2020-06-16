import 'package:flutter/material.dart';
import 'package:chatsakki/const.dart';
import 'package:photo_view/photo_view.dart';

class FullPhoto extends StatelessWidget {
  final String url;

  FullPhoto({Key key, @required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsIconTheme: IconThemeData(color: Colors.white),
        brightness: Brightness.dark,
        backgroundColor: Colors.transparent.withOpacity(0.9),
        title: Text(
          'Profile Image',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.edit), onPressed: (){}),
          IconButton(icon: Icon(Icons.share), onPressed: (){}),
        ],
      ),
      body: FullPhotoScreen(url: url),
      backgroundColor: Colors.black,
    );
  }
}

class FullPhotoScreen extends StatefulWidget {
  final String url;

  FullPhotoScreen({Key key, @required this.url}) : super(key: key);

  @override
  State createState() => FullPhotoScreenState(url: url);
}

class FullPhotoScreenState extends State<FullPhotoScreen> {
  final String url;

  FullPhotoScreenState({Key key, @required this.url});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Container(child: PhotoView(imageProvider: NetworkImage(url))));
  }
}
