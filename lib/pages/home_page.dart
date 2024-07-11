import 'dart:async';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:m/api/constant.dart';
import 'package:provider/provider.dart';

import 'package:m/api/api.dart';
import 'package:m/models/platform_account_data.dart';
import 'package:m/models/user_info.dart';

import 'package:m/components/alert_dialog.dart';
import 'package:m/pages/log_table_widget.dart';
import 'package:m/components/button_widget.dart';
import 'package:dropdown_search/dropdown_search.dart';

class HomePage extends StatefulWidget {
  final String baseUrl;

  const HomePage({Key? key, required this.baseUrl}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  
  String get _baseUrl => widget.baseUrl;
  // 是否定时
  bool _isTiming = false; 
  // 是否运行
  bool _isRun = false;
  // 日志
  List<PlatformAccountLog> _logDatas = [];
  // 所有任务
  List<PlatformAccountData> _tasks = [];
  // 完成任务
  final List<PlatformAccountData> _completeTasks = [];
  // 等待处理任务
  final List<PlatformAccountData> _waitTasks = [];
  List<Map> _shopDatas = [];
  Map? _selectedShop;
  // 处理单个任务定时器
  Timer? _taskTimer;
  // 处理定时
  Timer? _timer;

  int _updateConfigTime = 0;
  // 定时时间
  DateTime _timingTime = DateTime(2021, 10, 2, DateTime.now().hour + 1, 0, 0);

  static const _platform = MethodChannel('com.zc.m/battery');

  // ignore: unused_field
  String _batteryLevel = 'Unknown battery level.';

  Future<void> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int result = await _platform.invokeMethod('getBatteryLevel');
      batteryLevel = "Battery level at $result % .";
    } on PlatformException catch (e) {
      batteryLevel = "Failed to get battery level: '${e.toString()}'";
    }
    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  @override
  void initState() {
    super.initState();
    // _getBatteryLevel();
    _updateTasks();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateConfigTime++;
      if (_updateConfigTime == 10 * 60) {
        _updateConfigTime = 0;
        Api.updateConfig(true);
      }
      if (_isTiming) {
        // 执行定时任务
        var time = DateTime.now();
        if (time.hour == _timingTime.hour &&
            time.minute == _timingTime.minute &&
            time.second == _timingTime.second) {
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
    super.build(context);
    return _home(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _taskTimer?.cancel();
    _taskTimer = null;
    super.dispose();
  }

  // 运行任务
  _start() {
    if (!_isRun) {
      setState(() {
        _isRun = true;
      });
    }
    _completeTasks.clear();
    _waitTasks.clear();
    _waitTasks.addAll(_tasks);
    if (_taskTimer == null) {
      _runTask();
      _taskTimer = Timer.periodic(
          Duration(
              milliseconds: ((UserInfo().delayTime - 0.02) * 1000).toInt()),
          (timer) {
        _runTask();
      });
    }
  }

  _cancel() {
    _taskTimer?.cancel();
    _taskTimer = null;
    _cancelTiming();
    setState(() {
      _isRun = false;
    });
  }

  _cancelTiming() {
    setState(() {
      _isTiming = false;
    });
  }

  _startTiming() {
    setState(() {
      _isTiming = true;
    });
  }

  _clearLog() {
    setState(() {
      _logDatas = [];
    });
  }

  void _runTask() {
    if (_waitTasks.isEmpty) {
      return;
    }
    if (!_isRun || _waitTasks.isEmpty) {
      return;
    }
    final task = _waitTasks[0];
    _waitTasks.removeAt(0);
    // 更新日志
    void complete(String? result) {
      setState(() {
        _logDatas.insert(0, PlatformAccountLog(accountData: task, log: result));
      });
    }

    // 下单
    Api.createOrder(_baseUrl, task, _selectedShop ?? {}).then((value) {
      complete(value);
      _completeTasks.add(task);
    }).onError((error, stackTrace) {
      if (!error.toString().contains("黑名单")) {
        _waitTasks.add(task);
      }
      complete(error.toString());
    });
  }

  // 更新任务
  void _updateTasks() {
    _tasks = PlatformAccountData.datasFromString(UserInfo().platformAccount);
    if (_isRun) {
      _start();
    }
  }

  // 更新定时时间
  void _updateTimingTime() {
    var time = DateTime.now();
    var tempTime =
        DateTime(time.year, time.month, time.day, time.hour + 1, 0, 0);
    if (tempTime.hour != _timingTime.hour) {
      setState(() {
        _timingTime = tempTime;
      });
    }
  }

  // 退出
  void _logout() async {
    UserInfo().logout();
  }

  Future<List<Map>> _getShopItems(String filter) async {
    try {
      List<Map> data;
      if (_shopDatas.isNotEmpty) {
        data = _shopDatas;
      } else {
        data = await Api.getShopDatas(_baseUrl);
        _shopDatas = data;
      }
      if (filter.isEmpty) {
        return data;
      }
      List<Map> values = [];
      for (var item in data) {
        var name = item["c_name"];
        if (name is String && name.contains(filter)) {
          values.add(item);
        }
      }
      return values;
    } catch (e) {
      return [];
    }
  }

  Widget _home(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.max, children: [
      if (UserInfo().isActive) 
        Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 0),
        child: SizedBox(
          height: 50,
          child: DropdownSearch<Map>(
            popupProps: const PopupProps.menu(showSearchBox: true),
            asyncItems: (text) => _getShopItems(text),
            autoValidateMode: AutovalidateMode.always,
            clearButtonProps: const ClearButtonProps(isVisible: true),
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(hintText: "选择店铺"),
            ),
            itemAsString: (Map item) => item['c_name'],
            onChanged: (value) {
              _selectedShop = value is Map ? value : null;
            },
            filterFn: (Map item, filter) {
              var name = item["c_name"];
              return name is String && name.contains(filter);
            },
          ),
        ),
      ),
      Expanded(
        child: Container(
            child: LogTableWidget(_logDatas),
            decoration: BoxDecoration(
                color: Colors.grey[350],
                border: Border.all(
                  color: Colors.grey,
                  width: 0.5,
                ))),
      ),
      _buttonsUI()
    ]);
  }

  Widget _timeUI() {
    final time = DateFormat("HH:mm:ss").format(_timingTime);
    return Consumer<UserInfo>(builder: (context, userInfo, child) {
      return SizedBox(
        height: 60,
        child: Stack(
          children: [
            GestureDetector(
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    Text("间隔(秒):${UserInfo().delayTime}",
                        style:
                            TextStyle(color: Colors.yellow[200], fontSize: 15)),
                  ],
                ),
              ),
              onTap: () {
                showAlertDialog(context, "间隔", (val) {
                  try {
                    UserInfo().saveDelayTime(val);
                  } catch (_) {}
                }, placeholder: "秒");
              },
            ),
            SizedBox(
              height: 60,
              child: GestureDetector(
                child: Center(
                  child: Text(
                    time,
                    style: TextStyle(color: Colors.yellow[300], fontSize: 30),
                  ),
                ),
                onTap: () {
                  showAlertDialog(context, "时间", (value) {
                    if (value.isEmpty) {
                      return;
                    }
                    try {
                      List<int> times =
                          value.split(":").map((e) => int.parse(e)).toList();
                      var time =
                          DateTime(2021, 9, 12, times[0], times[1], times[2]);
                      setState(() {
                        _timingTime = time;
                      });
                    } catch (_) {}
                  }, placeholder: "时分秒，例如：10:00:00");
                },
              ),
            )
          ],
        ),
      );
    });
  }

  Widget _buttonsUI() {
    return Consumer<UserInfo>(builder: (context, userInfo, child) {
      return Container(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        height: 160,
        child: Column(
          children: [
            _timeUI(),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.maxFinite,
                    height: 45,
                    child: ButtonWidget(
                        onPressed: _isTiming ? _cancelTiming : _startTiming,
                        text: _isTiming ? "停止定时" : "定时"),
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
                        onPressed: _isRun ? _cancel : _start,
                        text: _isRun ? "停止" : "开始"),
                  ),
                ),
              ],
            ),
            Container(
              height: 10,
            ),
            Row(
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
                  width: 5,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ButtonWidget(
                        onPressed: () {
                          showAlertDialog(context, "登录信息", (value) {
                            UserInfo().updateLoginToken(value, _baseUrl);
                          }, placeholder: "请输入登录信息");
                        },
                        text: "登录信息"),
                  ),
                ),
                // if (userInfo.isActive)
                //   Container(
                //     width: 10,
                //   ),
                // if (userInfo.isActive)
                //   Expanded(
                //     child: SizedBox(
                //       width: double.infinity,
                //       height: 45,
                //       child: ButtonWidget(
                //           onPressed: () {
                //             showModalBottomSheet(
                //                 context: context,
                //                 isScrollControlled: true,
                //                 builder: (context) {
                //                   return const QueryAvailablePage();
                //                 });
                //           },
                //           text: "查降权"),
                //     ),
                //   ),
                Container(
                  width: 5,
                ),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ButtonWidget(
                      text: "配置",
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (context1) => SizedBox.expand(
                              child: SingleChildScrollView(
                                primary: true,
                                child: SafeArea(
                                  bottom: false,
                                  child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      title: const Text("任务id"),
                                      onTap: () =>  showAlertDialog(context, "任务id", (value) {
                                        userInfo.saveConfig(
                                            platformAccount: value);
                                        _updateTasks();
                                      }, placeholder: "换行分隔"),
                                    ),
                                    ListTile(
                                     title: const Text("过滤数据id"),
                                     onTap: () => showAlertDialog(context, "过滤数据id", (value) {
                                        userInfo.saveConfig(
                                            filterDataIds: value);
                                        _updateTasks();
                                      }, placeholder: "换行分隔"),
                                    )
                                  ],
                                ),
                                )
                              ),
                            ));
                      },
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    });
  }
  
  @override
  bool get wantKeepAlive => true;
}
