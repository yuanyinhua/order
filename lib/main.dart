import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:task/models/user_info.dart';

import 'package:task/pages/home_page.dart';
import 'package:task/pages/root_page.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => UserInfo(),
      child: MyApp(),
    ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RootPage(),
    );
  }
}


