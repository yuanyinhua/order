import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:task/api/api.dart';
import 'package:task/models/platform_account_data.dart';
import 'package:task/models/user_info.dart';
import 'package:task/views/button_widget.dart';
import 'package:task/views/log_table_widget.dart';
import 'package:task/views/alert_dialog.dart';

class QueryAvailablePage extends StatefulWidget {
  QueryAvailablePage({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _QueryAvailablePageState();
  }
}

class _QueryAvailablePageState extends State<QueryAvailablePage> {
  List<PlatformAccountLog> _logDatas = [];
  bool isRun = true;
  List<PlatformAccountData> _tasks = [];
  @override
  Widget build(BuildContext context) {
    MediaQueryData mq = MediaQuery.of(context);
    return SafeArea(
        child: SizedBox(
      height: mq.size.height - mq.padding.top - mq.padding.bottom - 50,
      child: Column(
        children: [
          _header(),
          Expanded(
              child: SizedBox(
            height: double.infinity,
            child: LogTableWidget(_logDatas),
          )),
          _bottomUI(context)
        ],
      ),
    ));
  }

  Widget _bottomUI(BuildContext context) {
    return Container(
      height: 50,
      padding: EdgeInsets.only(left: 10, right: 10),
      child: Row(
        children: [
          Expanded(
              child: SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              text: "修改",
              onPressed: () {
                showAlertDialog(context, "修改任务", "", (value) {
                  setState(() {
                    _tasks = PlatformAccountData.datasFromString(value);
                  });
                });
              },
            ),
          )),
          if (!isRun)
            Container(
              width: 10,
            ),
          if (!isRun)
            Expanded(
                child: SizedBox(
              width: double.infinity,
              child: ButtonWidget(
                text: "开始",
                onPressed: _start,
              ),
            )),
        ],
      ),
    );
  }

  Widget _header() {
    return SizedBox(
      height: 35,
      child: Stack(
        children: [
          Center(
            child: Text(
              "查降权",
              style: TextStyle(color: Colors.black),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                child: SizedBox(
                  child: Center(
                    child: Icon(Icons.close),
                  ),
                  width: 44,
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              )
            ],
            mainAxisAlignment: MainAxisAlignment.end,
          )
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tasks = List.from(
        PlatformAccountData.datasFromString(UserInfo().platformAccount));
    _start();
  }

  void _start() async {
    setState(() {
      isRun = true;
    });
    // 更新日志
    void complete(PlatformAccountData task, String? result) {
      setState(() {
        _logDatas.insert(0, PlatformAccountLog(accountData: task, log: result));
      });
    }

    await Future.wait(_tasks.map((e) => Api.queryTaskAvailable(e).then((value) {
          complete(e, value);
        }).onError((error, stackTrace) {
          complete(e, error.toString());
        })));
    setState(() {
      isRun = false;
    });
  }
}
