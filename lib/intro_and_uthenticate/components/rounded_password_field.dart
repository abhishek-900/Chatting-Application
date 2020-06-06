import 'package:flutter/material.dart';

import '../constants.dart';
import 'text_field_container.dart';

class RoundedPasswordField extends StatefulWidget {
  final ValueChanged<String> onChanged;
  const RoundedPasswordField({
    Key key,
    this.onChanged,
  }) : super(key: key);

  @override
  _RoundedPasswordFieldState createState() => _RoundedPasswordFieldState();
}

class _RoundedPasswordFieldState extends State<RoundedPasswordField> {
  bool _obscured;
  Icon ic;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _obscured = true;
    ic = Icon(
      Icons.visibility,
      color: kPrimaryColor,);
  }
  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
      child: TextField(
        obscureText: _obscured,
        onChanged: widget.onChanged,
        cursorColor: kPrimaryColor,
        decoration: InputDecoration(
          hintText: "Password",
          icon: Icon(
            Icons.lock,
            color: kPrimaryColor,
          ),
          suffixIcon: IconButton(
            icon: ic,
            onPressed: (){
              this.setState(() {
                _obscured = !_obscured;
                if(_obscured)
                    ic = Icon(
                      Icons.visibility,
                      color: kPrimaryColor,);
                else
                  ic = Icon(
                    Icons.visibility_off,
                    color: kPrimaryColor,);
              });
            },
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
