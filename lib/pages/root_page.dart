import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:m/api/api.dart';

import 'package:m/models/user_info.dart';
import 'package:m/components/loading_widget.dart';

import 'home_page.dart';
import 'login_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({Key? key}) : super(key: key);
  @override
  _RootPageState createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // 是否加载完成
  final Future<bool>? _loading = Api.load();

  @override
  void initState() {
    super.initState();
  }

  void hiddenKeyword() {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus!.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          child: SafeArea(
            child: FutureBuilder(
                future: _loading,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: LoadingWidget(),
                    );
                  }
                  return Consumer<UserInfo>(
                      builder: (context, userInfo, child) {
                    return userInfo.isLogin ? const HomePage() : const LoginPage();
                  });
                }),
          ),
        ),
        backgroundColor: const Color.fromRGBO(191, 191, 190, 1));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
