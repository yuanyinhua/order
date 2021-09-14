import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'api.dart';
import 'user_info.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? qrCode;
  int reqCount = 0;
  final reqCountMax = 100;
  var islogin = false;
  var isLoading = true;
  bool isTiming = false;
  bool isAutoRun = false;
  List<Map> logDatas = [];
  int queueCount = 1;
  List<Map> tasks = [];
  List<Map> completeTasks = [];
  Timer? taskTimer;
  Timer? timingTimer;
  DateTime timingTime = DateTime.now();
  double delayTime = 2;
  int i = 0;
  // 运行任务
  _start() {
    if (!isAutoRun) {
      setState(() {
       isAutoRun = true;
      });
    }
    i = 0;
    completeTasks.clear();
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
      isAutoRun = false;
    });
  }

  _cancelTiming() {
    timingTimer?.cancel();
    timingTimer = null;
    setState(() {
      isTiming = false;
    });
  }

  _startTiming() {
    taskTimer?.cancel();
    timingTimer?.cancel();
    timingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      var time = DateTime.now();
      if (time.hour == timingTime.hour &&
          time.minute == timingTime.minute &&
          time.second == timingTime.second) {
        _start();
        _cancelTiming();
      }
    });
    setState(() {
      isTiming = true;
    });
  }

  _clearLog() {
    setState(() {
      logDatas = [];
    });
  }

  _showAlertDialog(
      BuildContext context, String title, Function(String) complete) {
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
              height: 80,
              child: Column(
                children: [
                  TextField(controller: code, maxLines: 2),
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

  void runTask() {
    if (completeTasks.length == tasks.length) {
      return;
    }
    if (!isAutoRun ||
        (tasks.length == 0 && tasks.length == 0) ||
        i >= tasks.length) {
      return;
    }
    if (i >= tasks.length) {
      for (var item in completeTasks) {
        tasks.removeWhere((element) => element == item);
      }
      i = 0;
    }
    final task = tasks[i];
    i++;
    Api.autoAddOrder(task["code"], task["platform"] as int).then((value) {
      setState(() {
        logDatas.insertAll(0, value);
      });
      completeTasks.add(task);
    }).onError((error, stackTrace) {
      if (!UserInfo().isLogin) {
        _logout();
      }
    });
  }

  void _loading() async {
    try {
      bool isSuccess = await Api.load();
      setState(() {
        isLoading = false;
        islogin = isSuccess;
      });
      _updateTasks();
    } catch (e) {}
  }

  void _updateTasks() {
    if (UserInfo().code.length == 0) {
      return;
    }
    List<String> codes = UserInfo().code.split("\n");
    List<Map> datas = [];
    for (var i = 1; i <= 1; i++) {
      datas.addAll(codes.map((e) => {"code": e.trim(), "platform": i}));
    }
    tasks = datas;
    if (isAutoRun) {
      _start();
    }
  }

  @override
  void initState() {
    super.initState();
    _loading();
    Api.login(null);
  }

  // 获取
  // ignore: unused_element
  void _getqrCodeData() {
    Api.qrCodeData().then((data) {
      setState(() {
        qrCode = data as String;
      });
      _waitScan();
    });
  }

  void _retryWaitScan() {
    setState(() {
      reqCount = 0;
    });
    _waitScan();
  }

  // 等待扫一扫
  void _waitScan() async {
    Api.waitScan().then((data) {
      Api.login(data);
    }).onError((error, stackTrace) {
      setState(() {
        reqCount += 1;
        if (reqCount <= reqCountMax) {
          _waitScan();
        }
      });
    });
  }

  void _login(String token, String password) async {
    try {
      if (password != "10496") {
        return;
      }
      await UserInfo().updateCookie(token);
      setState(() {
        islogin = true;
      });
    } catch (e) {}
  }

  void _logout() {
    UserInfo().updateCookie(null);
    _cancel();
    _cancelTiming();
    setState(() {
      islogin = false;
    });
  }

  Widget qrImage() {
    return Row(
      children: [
        Stack(
          children: [
            QrImage(
              data: qrCode!,
              size: 250,
            ),
            if (reqCount > reqCountMax)
              GestureDetector(
                child: Container(
                  child: Center(
                      child: Text(
                    "二维码失效,点击重试",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  )),
                  width: 250,
                  height: 250,
                  color: Colors.white.withOpacity(0.9),
                ),
                onTap: _retryWaitScan,
              )
          ],
        )
      ],
    );
  }

  Widget loginUI() {
    final token = TextEditingController();
    final password = TextEditingController();
    return Center(
        child: Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      height: 270,
      child: Column(
        children: [
          TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: "输入登录信息"),
            controller: token,
          ),
          TextField(
            obscureText: true,
            decoration: InputDecoration(hintText: "认证信息"),
            controller: password,
          ),
          Container(
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  _login(token.text, password.text);
                },
                child: Text("登录", style: TextStyle(color: Colors.black87)),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                        Color.fromRGBO(208, 208, 208, 1))),
              ),
            ),
            margin: EdgeInsets.only(top: 10),
          )
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (isLoading) {
      body = Center(
          child: CupertinoActivityIndicator(
        animating: true,
        radius: 10,
      ));
    } else {
      body = islogin ? home(context) : loginUI();
    }
    return Scaffold(
        extendBody: true,
        body: body,
        backgroundColor: Color.fromRGBO(191, 191, 190, 1));
  }

  Widget home(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.max, children: [
      Expanded(
        child: Container(
            margin: EdgeInsets.only(top: 20),
            child: tableUI(),
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
      height: 50,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                  onTap: _logout,
                  child: Center(
                    child: Text("退出",
                        style:
                            TextStyle(color: Colors.yellow[200], fontSize: 15)),
                  )),
            ],
          ),
          GestureDetector(
            child: SizedBox(
              height: 50,
              child: Row(
                children: [
                  Text("间隔$delayTime",
                      style:
                          TextStyle(color: Colors.yellow[200], fontSize: 15)),
                ],
              ),
            ),
            onTap: () {
              _showAlertDialog(context, "间隔", (val) {
                try {
                  setState(() {
                    delayTime = max(0.2, double.parse(val));
                  });
                } catch (e) {}
              });
            },
          ),
          Container(
            height: 50,
            child: GestureDetector(
              child: Center(
                child: Text(
                  time,
                  style: TextStyle(color: Colors.yellow[300], fontSize: 30),
                ),
              ),
              onTap: () {
                _showAlertDialog(context, "时间", (value) {
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
                          style: TextStyle(color: Colors.black87),
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
                        onPressed: isAutoRun ? _cancel : _start,
                        child: SizedBox(
                            child: Text(
                          isAutoRun ? "停止" : "开始",
                          style: TextStyle(color: Colors.black87),
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
                        onPressed: _clearLog,
                        child: SizedBox(
                            child: Text(
                          "清除日志",
                          style: TextStyle(color: Colors.black87),
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
                          _showAlertDialog(context, "账号", (value) {
                            UserInfo().updateCode(value);
                            _updateTasks();
                          });
                        },
                        child: SizedBox(
                            child: Text(
                          "账号",
                          style: TextStyle(color: Colors.black87),
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

  Widget tableUI() {
    var columnWidths = {
      0: FixedColumnWidth(80),
      1: FlexColumnWidth(),
    };
    Widget header = Table(
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      columnWidths: columnWidths,
      children: [
        TableRow(
            decoration: BoxDecoration(
              color: Colors.grey[350],
            ),
            children: [
              for (var item in ["账号", "日志"])
                //增加行高
                SizedBox(
                  height: 32.0,
                  child: Center(
                    child: Text(
                      item,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ]),
      ],
    );
    Widget table = Table(
      border: TableBorder.all(color: Colors.grey, width: 0.5),
      columnWidths: columnWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (var item in logDatas)
          TableRow(children: [
            SizedBox(
              height: 30,
              child: Center(
                child: Text(
                  item["code"],
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Text(
              item["name"],
              textAlign: TextAlign.center,
            )
          ])
      ],
    );
    return Column(
      children: [
        header,
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              child: table,
            ),
            scrollDirection: Axis.vertical,
          ),
        ),
      ],
    );
  }
}
