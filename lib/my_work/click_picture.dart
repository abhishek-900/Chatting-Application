import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ClickPicture extends StatefulWidget {
  final CameraDescription camera;
  final String groupChatId;
  final String peerId;
  final String id;

  const ClickPicture(
      {Key key, @required this.camera, this.groupChatId, this.peerId, this.id})
      : super(key: key);

  @override
  _ClickPictureState createState() => _ClickPictureState();
}

class _ClickPictureState extends State<ClickPicture> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  bool pictureTaken;
  String path;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    pictureTaken = false;
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );
    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            await _initializeControllerFuture;
            var directory = await getExternalStorageDirectory();
            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              directory.path,
              'Pictures','${DateTime.now()}.jpeg',
            );
print(path);
            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  imagePath: path,
                  groupChatId: widget.groupChatId,
                  id: widget.id,
                  peerId: widget.peerId,
                ),
              ),
            );
//              listScrollController.animateTo(0.0,
//                  duration: Duration(milliseconds: 300), curve: Curves.easeOut);

          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath, groupChatId, id, peerId;
  const DisplayPictureScreen(
      {Key key, this.imagePath, this.id, this.peerId, this.groupChatId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var path = File(imagePath);
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.send),
        onPressed: () {
          print("sending...........${path.path}");
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
                'content': path.path,
                'type': 1,
                'isSeen': 'Delivered'
              },
            );
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}
