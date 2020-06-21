import 'package:flutter/material.dart';
class ChatBubble extends StatefulWidget {
  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
   double _fontsize=20.0;
   final double _basefontsize=20.0;
     double _fontscale=1;
       double _basefontscale=1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          child: Container(
        padding: EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),bottomLeft: Radius.circular(15),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
          [Colors.lightBlue,Colors.blue]),
          boxShadow: [BoxShadow(
            blurRadius: 20.0,
            offset: Offset(10, 10),
            color: Colors.black54)]
        ),
        constraints: BoxConstraints(maxWidth: 330),
        child:Text.rich(
          buildTextSpan(),
          strutStyle: StrutStyle(
            fontSize: _fontsize
          ),
        ),

      ),
    );
  }

  TextSpan buildTextSpan(){
    return TextSpan(
      style: TextStyle(fontSize: _fontsize),
      children: [
        TextSpan(text:"Hello moteya kesa h ???"),
        TextSpan(text:"blah blah blah blah blah"),
        TextSpan(text:"blah blah blah blah blah blah blah blah blah blah blah blah ???"),

      ]
    );

  }
}
