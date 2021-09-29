import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:task/api/api.dart';
import 'package:task/tools/error.dart';
import 'package:task/models/platform_account_data.dart';
import 'package:task/models/user_info.dart';
import 'package:task/views/log_table_widget.dart';

class QueryAvailablePage extends StatefulWidget {
  QueryAvailablePage({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _QueryAvailablePageState();
  }
}

class _QueryAvailablePageState extends State<QueryAvailablePage> {
  double _delayTime = UserInfo().config.queryDelayTime;
  List<PlatformAccountLog> _logDatas = [];
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height - 50,
      child: Column(
        children: [
          SizedBox(
            height: 35,
            child: Stack(
              children: [
                Center(
                  child: Text("查降权", style: TextStyle(color: Colors.black),),
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
          ),
          Expanded(
              child: SizedBox(
            height: double.infinity,
            child: LogTableWidget(_logDatas),
          ))
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _queryAllTaskAvailable(List.from(UserInfo().config.platformAccountDatas));
  }

  // 查询下单账号状态
  void _queryAllTaskAvailable(List<PlatformAccountData> tasks) {
    if (tasks.length == 0) {
      return;
    }
    // 循环
    Function loop = (List<PlatformAccountData> tasks) {
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
      } else if (error is MError && error.code == -100) {
        _delayTime += 0.1;
        UserInfo().saveConfig(queryDelayTime: _delayTime);
      } else {
        complete(task, error.toString());
        tasks.removeAt(0);
        tasks.add(task);
      }
      loop(tasks);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
