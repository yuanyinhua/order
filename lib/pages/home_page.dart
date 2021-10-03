import 'dart:async';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:task/api/api.dart';
import 'package:task/tools/error.dart';
import 'package:task/models/platform_account_data.dart';
import 'package:task/models/user_info.dart';
import 'package:task/pages/query_available_page.dart';

import 'package:task/views/alert_dialog.dart';
import 'package:task/views/log_table_widget.dart';
import 'package:task/views/button_widget.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
  DateTime timingTime = DateTime(2021, 10, 2, DateTime.now().hour + 1, 0, 0);

  @override
  void initState() {
    super.initState();
    _updateTasks();
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
    return home(context);
  }

  @override
  void dispose() {
    timer?.cancel();
    timer = null;
    taskTimer?.cancel();
    taskTimer = null;
    super.dispose();
  }

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
          Duration(milliseconds: ((UserInfo().delayTime) * 1000).toInt()),
          (timer) {
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
    // 更新日志
    void complete(String? result) {
      setState(() {
        logDatas.insert(0, PlatformAccountLog(accountData: task, log: result));
      });
    }

    // 下单
    Api.createOrder(task).then((value) {
      complete(value);
      completeTasks.add(task);
    }).onError((error, stackTrace) {
      if (error is MError && error.code == -1) {
        completeTasks.add(task);
      } else {
        waitTasks.add(task);
      }
      complete(error.toString());
    });
  }

  // 更新任务
  void _updateTasks() {
    tasks = PlatformAccountData.datasFromString(UserInfo().platformAccount);
    if (isRun) {
      _start();
    }
  }

  // 更新定时时间
  void _updateTimingTime() {
    var time = DateTime.now();
    var tempTime = DateTime(time.year, time.month, time.day, time.hour + 1, 0, 0);
    if (tempTime.hour != timingTime.hour) {
      setState(() {
        timingTime = tempTime;
      });
    }
  }

  void _logout() async {
    UserInfo().isLogin = false;
  }

  Widget home(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.max, children: [
      Expanded(
        child: Container(
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
    return Consumer<UserInfo>(builder: (context, userInfo, child) {
      return Container(
        height: 60,
        child: Stack(
          children: [
            if (userInfo.isActive)
              GestureDetector(
                child: SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      Text("间隔(秒):${UserInfo().delayTime}",
                          style: TextStyle(
                              color: Colors.yellow[200], fontSize: 15)),
                    ],
                  ),
                ),
                onTap: () {
                  showAlertDialog(context, "间隔", "秒", (val) {
                    try {
                      setState(() {
                        UserInfo()
                            .saveConfig(delayTime: max(0.1, double.parse(val)));
                      });
                    } catch (e) {}
                  });
                },
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
    });
  }

  Widget buttonsUI() {
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
                    child: ButtonWidget(
                        onPressed: isTiming ? _cancelTiming : _startTiming,
                        text: isTiming ? "停止定时" : "定时"),
                  ),
                ),
                Container(
                  width: 10,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.maxFinite,
                    height: 45,
                    child: ButtonWidget(
                        onPressed: isRun ? _cancel : _start,
                        text: isRun ? "停止" : "开始"),
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
                    child: ButtonWidget(
                      onPressed: _logout,
                      text: "退出",
                    ),
                  ),
                ),
                Container(
                  width: 5,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ButtonWidget(onPressed: _clearLog, text: "清除日志"),
                  ),
                ),
                Container(
                  width: 10,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ButtonWidget(
                        onPressed: () {
                          showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) {
                                return QueryAvailablePage();
                              });
                        },
                        text: "查降权"),
                  ),
                ),
                Container(
                  width: 5,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ButtonWidget(
                        onPressed: () {
                          showAlertDialog(context, "任务id", "换行分隔", (value) {
                            UserInfo().saveConfig(platformAccount: value);
                            _updateTasks();
                          });
                        },
                        text: "配置"),
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
