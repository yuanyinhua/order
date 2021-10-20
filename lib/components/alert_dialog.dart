import 'package:flutter/material.dart';

showAlertDialog(BuildContext context, String title,
  Function(String) complete, {bool obscureText = false, String placeholder = ""}) {
    var code = TextEditingController();
    //显示对话框
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, state) {
          return AlertDialog(
            titlePadding: EdgeInsets.only(left: 20, top: 10),
            contentPadding: EdgeInsets.only(left: 20, right: 20, bottom: 0),
            buttonPadding: EdgeInsets.only(right: 20),
            title: Text(title),
            content: Container(
              height: 100,
              child: Column(
                children: [
                  TextField(
                    obscureText: obscureText,
                    controller: code,
                    maxLines: obscureText ? 1 : 3,
                    minLines: 1,
                    decoration: InputDecoration(hintText: placeholder),
                  ),
                  Container(
                    height: 10,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text("保存"),
                onPressed: () {
                  complete(code.text);
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }