import 'package:fluttertoast/fluttertoast.dart';

class MyToast {
  static showToast(String msg) {
    Fluttertoast.showToast(
        msg: msg,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 2,
        fontSize: 14.0);
  }
}
