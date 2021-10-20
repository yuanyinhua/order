import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:task/api/api.dart';

import 'package:task/components/alert_dialog.dart';
import 'package:task/components/button_widget.dart';
import 'package:task/models/platform_account_data.dart';
import 'package:task/models/user_info.dart';
import 'package:task/pages/log_table_widget.dart';

class QueryAvailablePage extends StatefulWidget {
  QueryAvailablePage({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _QueryAvailablePageState();
  }
}

class _QueryAvailablePageState extends State<QueryAvailablePage> {
  List<PlatformAccountLog> _logDatas = [];
  // 是否运行
  bool _isRun = false;
  // 延迟时间
  double _delayTime = 1;
  // 定时器
  Timer? _timer;
  // 任务
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
              text: "修改任务",
              onPressed: () {
                showAlertDialog(context, "修改任务", (value) {
                  setState(() {
                    _tasks = PlatformAccountData.datasFromString(value);
                  });
                });
              },
            ),
          )),
          Container(
            width: 10,
          ),
          Expanded(
              child: SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              text: "延迟时间",
              onPressed: () {
                showAlertDialog(context, "延迟时间（秒）", (value) {
                  _delayTime = double.parse(value);
                }, placeholder: "请输入延迟时间");
              },
            ),
          )),
          Container(
            width: 10,
          ),
          Expanded(
              child: SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              text: _isRun ? "停止" : "开始",
              onPressed: _isRun ? _stop : _start,
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
  }

  void _stop() async {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRun = false;
    });
  }

  void _start() async {
    setState(() {
      _isRun = true;
    });
    // 更新日志
    void complete(PlatformAccountData task, String? result) {
      setState(() {
        _logDatas.insert(0, PlatformAccountLog(accountData: task, log: result));
      });
      if (_tasks.isEmpty) {
        _stop();
      }
    }

    _timer = Timer.periodic(Duration(milliseconds: (_delayTime * 1000).toInt()),
        (timer) async {
      PlatformAccountData task = _tasks.removeAt(0);
      try {
        var value = await Api.queryTaskAvailable(task);
        complete(task, value);
      } catch (e) {
        complete(task, e.toString());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
