import 'package:flutter/material.dart';
import 'package:task/api/api.dart';
import 'package:task/api/error.dart';
import 'package:task/models/platform_account_data.dart';
import 'package:task/views/log_table_widget.dart';

class QueryAvailablePage extends StatefulWidget {
  QueryAvailablePage({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _QueryAvailablePageState();
  }
}

class _QueryAvailablePageState extends State<QueryAvailablePage> {
  final double _delayTime = 0.5;
  List<PlatformAccountLog> _logDatas = [];
  final List<PlatformAccountData> _tasks = [];
  bool isRun = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        child: LogTableWidget(_logDatas),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _queryAllTaskAvailable(List.from(_tasks));
  }

  // 查询下单账号状态
  void _queryAllTaskAvailable(List<PlatformAccountData> tasks) {
    if (tasks.length == 0 || !isRun) {
      return;
    }
    // 循环
    Function loop = (List<PlatformAccountData> tasks) {
      if (!isRun) {
        return;
      }
      Future.delayed(Duration(milliseconds: (_delayTime * 1000).toInt()))
          .then((value) {
        _queryAllTaskAvailable(tasks);
      });
    };
    // 更新日志
    void complete(PlatformAccountData task, String? result) {
      setState(() {
        _logDatas.insert(0, PlatformAccountLog(accountData: task, log: result));
      });
    }

    // 查询结果
    PlatformAccountData task = tasks[0];
    Api.queryTaskAvailable(task).then((value) {
      complete(task, value);
      tasks.removeAt(0);
      loop(tasks);
    }).onError((error, stackTrace) {
      if (error is MError && error.code == -1) {
        complete(task, error.toString());
        tasks.removeAt(0);
      }
      loop(tasks);
    });
  }
}
