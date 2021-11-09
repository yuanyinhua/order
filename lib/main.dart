import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:m/models/user_info.dart';
import 'package:m/pages/root_page.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  runApp(ChangeNotifierProvider(
      create: (context) => UserInfo(),
      child: const MyApp(),
    ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RootPage(),
      builder: EasyLoading.init(),
    );
  }
}


