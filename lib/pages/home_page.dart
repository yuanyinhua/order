import 'dart:async';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:task/api/api.dart';
import 'package:task/api/error.dart';
import 'package:task/models/platform_account_data.dart';
import 'package:task/models/user_info.dart';
import 'package:task/model/my_cookies.dart';
import '../my_router.dart';

import 'package:task/views/alert_dialog.dart';
import 'package:task/views/loading_widget.dart';
import 'package:task/views/log_table_widget.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _loading();
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (isTiming) {
        // 执行定时任务
        var time = DateTime.now();
        if (time.hour == timingTime.hour &&
            time.minute == timingTime.minute &&
            time.second == timingTime.second) {
          _start();
          _updateTimingTime();
        }
      } else {
        _updateTimingTime();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (isLoading) {
      body = LoadingWidget();
    } else {
      body = islogin
          ? home(context)
          : LoginPage(() {
              setState(() {
                islogin = true;
                isActive = UserInfo().config.isActive;
              });
            });
    }
    return Scaffold(
        extendBody: true,
        body: SafeArea(
          child: Stack(
            children: [MyCookies().getToken(() {}), body],
          ),
        ),
        backgroundColor: Color.fromRGBO(191, 191, 190, 1));
  }

  @override
  void dispose() {
    _cancel();
    timer?.cancel();
    super.dispose();
  }

  // 是否登录
  var islogin = false;
  // 是否激活
  var isActive = false;
  // 是否加载完成
  var isLoading = true;
  // 是否定时
  bool isTiming = false;
  // 是否运行
  bool isRun = false;
  // 日志
  List<PlatformAccountLog> logDatas = [];
  // 所有任务
  List<PlatformAccountData> tasks = [];
  // 完成任务
  List<PlatformAccountData> completeTasks = [];
  // 等待处理任务
  List<PlatformAccountData> waitTasks = [];
  // 处理单个任务定时器
  Timer? taskTimer;
  // 处理定时
  Timer? timer;
  // 定时时间
  DateTime timingTime = DateTime.now();
  // 任务处理间隔
  double delayTime = 1.2;
  // 运行任务
  _start() {
    if (!isRun) {
      setState(() {
        isRun = true;
      });
    }
    completeTasks.clear();
    waitTasks.clear();
    waitTasks.addAll(tasks);
    if (taskTimer == null) {
      runTask();
      taskTimer = Timer.periodic(
          Duration(milliseconds: ((delayTime) * 1000).toInt()), (timer) {
        runTask();
      });
    }
  }

  _cancel() {
    taskTimer?.cancel();
    taskTimer = null;
    _cancelTiming();
    setState(() {
      isRun = false;
    });
  }

  _cancelTiming() {
    setState(() {
      isTiming = false;
    });
  }

  _startTiming() {
    taskTimer?.cancel();
    setState(() {
      isTiming = true;
    });
  }

  _clearLog() {
    setState(() {
      logDatas = [];
    });
  }

  void runTask() {
    if (waitTasks.length == 0) {
      return;
    }
    if (!isRun || waitTasks.length == 0) {
      return;
    }
    final task = waitTasks[0];
    waitTasks.removeAt(0);

    Api.autoAddOrder(task).then((value) {
      logDatas.insert(0, PlatformAccountLog(accountData: task, log: value));
      completeTasks.add(task);
    }).onError((error, stackTrace) {
      if (error is MError && error.code == -1) {
        completeTasks.add(task);
      } else {
        waitTasks.add(task);
      }
      logDatas.insert(0, PlatformAccountLog(accountData: task, log: error.toString()));
    });
  }

  // 加载
  void _loading() async {
    try {
      bool isSuccess = await Api.load();
      setState(() {
        isLoading = false;
        islogin = isSuccess;
        isActive = UserInfo().config.isActive;
      });
      _updateTasks();
    } catch (e) {}
  }

  // 更新任务
  void _updateTasks() {
    tasks = UserInfo().config.platformAccountDatas;
    if (isRun) {
      _start();
    }
  }

  // 更新定时时间
  void _updateTimingTime() {
    var time = DateTime.now();
    var tempTime = DateTime(2021, 9, 12, time.hour + 1, 0, 0);
    if (tempTime.hour != timingTime.hour) {
      setState(() {
        timingTime = tempTime;
      });
    }
  }

  void _logout() {
    _cancel();
    _cancelTiming();
    setState(() {
      islogin = false;
    });
  }

  Widget home(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.max, children: [
      Expanded(
        child: Container(
            margin: EdgeInsets.only(top: 20),
            child: LogTableWidget(logDatas),
            decoration: BoxDecoration(
                color: Colors.grey[350],
                border: Border.all(
                  color: Colors.grey,
                  width: 0.5,
                ))),
      ),
      buttonsUI()
    ]);
  }

  Widget timeUI() {
    final time = DateFormat("HH:mm:ss").format(timingTime);
    return Container(
      height: 60,
      child: Stack(
        children: [
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: [
          //     GestureDetector(
          //         onDoubleTap: _logout,
          //         child: SizedBox(
          //           height: 60,
          //           width: 50,
          //           child: Text(""),
          //         )),
          //   ],
          // ),
          if (isActive)
            Column(
              children: [
                GestureDetector(
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        Text("间隔(秒):$delayTime",
                            style: TextStyle(
                                color: Colors.yellow[200], fontSize: 15)),
                      ],
                    ),
                  ),
                  onTap: () {
                    if (!isActive) {
                      return;
                    }
                    showAlertDialog(context, "间隔", "秒", (val) {
                      try {
                        setState(() {
                          delayTime = max(0.1, double.parse(val));
                        });
                      } catch (e) {}
                    });
                  },
                ),
              ],
            ),
          Container(
            height: 60,
            child: GestureDetector(
              child: Center(
                child: Text(
                  time,
                  style: TextStyle(color: Colors.yellow[300], fontSize: 30),
                ),
              ),
              onTap: () {
                showAlertDialog(context, "时间", "时分秒，例如：10:00:00", (value) {
                  if (value.length == 0) {
                    return;
                  }
                  try {
                    List<int> times =
                        value.split(":").map((e) => int.parse(e)).toList();
                    var time =
                        DateTime(2021, 9, 12, times[0], times[1], times[2]);
                    setState(() {
                      timingTime = time;
                    });
                  } catch (e) {}
                });
              },
            ),
          )
        ],
      ),
    );
  }

  Widget buttonsUI() {
    final style = ButtonStyle(
        backgroundColor:
            MaterialStateProperty.all(Color.fromRGBO(208, 208, 208, 1)));
    final textStyle = TextStyle(color: Colors.black87, fontSize: 12);
    return Container(
      margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
      height: 160,
      child: Column(
        children: [
          timeUI(),
          Container(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.maxFinite,
                    height: 45,
                    child: ElevatedButton(
                        style: style,
                        onPressed: isTiming ? _cancelTiming : _startTiming,
                        child: SizedBox(
                            child: Text(
                          isTiming ? "停止定时" : "定时",
                          style: textStyle,
                        ))),
                  ),
                ),
                Container(
                  width: 10,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.maxFinite,
                    height: 45,
                    child: ElevatedButton(
                        style: style,
                        onPressed: isRun ? _cancel : _start,
                        child: SizedBox(
                            child: Text(
                          isRun ? "停止" : "开始",
                          style: textStyle,
                        ))),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 10,
          ),
          Container(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                        style: style,
                        onPressed: _logout,
                        child: SizedBox(
                            child: Text(
                          "退出",
                          style: textStyle,
                        ))),
                  ),
                ),
                Container(
                  width: 5,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                        style: style,
                        onPressed: _clearLog,
                        child: SizedBox(
                            child: Text(
                          "清除日志",
                          style: textStyle,
                        ))),
                  ),
                ),
                Container(
                  width: 10,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                        style: style,
                        onPressed: () {
                          MyRouter.pushNoParams(context, "app://query");
                        },
                        child: SizedBox(
                            child: Text(
                          "查降权",
                          style: textStyle,
                        ))),
                  ),
                ),
                Container(
                  width: 5,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                        style: style,
                        onPressed: () {
                          showAlertDialog(context, "账号", "换行分隔", (value) {
                            UserInfo().saveConfig(platformAccounts: value);
                            _updateTasks();
                          });
                        },
                        child: SizedBox(
                            child: Text(
                          "配置账号",
                          style: textStyle,
                        ))),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}