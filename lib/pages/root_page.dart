import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:task/api/api.dart';

import 'package:task/models/user_info.dart';
import 'package:task/views/loading_widget.dart';

import 'home_page.dart';
import 'login_page.dart';

class RootPage extends StatefulWidget {
  RootPage({Key? key}) : super(key: key);
  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // 是否加载完成
  Future<bool>? _loading = Api.load();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: FutureBuilder(
            future: _loading,
            builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: LoadingWidget(),
              );
            }
            return Consumer<UserInfo>(builder: (context, userInfo, child) {
              return userInfo.isLogin ? HomePage() : LoginPage();
            });
          }),
        ),
        backgroundColor: Color.fromRGBO(191, 191, 190, 1));
  }

  @override
  void dispose() {
    super.dispose();
  }

}
