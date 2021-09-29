import 'package:fluttertoast/fluttertoast.dart';
// import 'package:flutter/material.dart';

class MyToast {
  static showToast(String msg) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 2,
        fontSize: 16.0);
  }
}
