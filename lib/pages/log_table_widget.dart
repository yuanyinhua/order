import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m/components/my_toast.dart';
import 'package:m/models/platform_account_data.dart';
 
 class LogTableWidget extends StatelessWidget {
  final List<PlatformAccountLog> logDatas;
  const LogTableWidget(this.logDatas, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return tableUI();
  }

  Widget tableUI() {
    var columnWidths = {
      0: const FixedColumnWidth(120),
      1: const FlexColumnWidth(),
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
              for (var item in ["任务id", "日志"])
                //增加行高
                SizedBox(
                  height: 32.0,
                  child: Center(
                    child: Text(
                      item,
                      style: const TextStyle(
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
                child: GestureDetector(
                  onLongPress: (){
                    Clipboard.setData(ClipboardData(text: item.accountData.name));
                    MyToast.showToast("复制成功");
                  },
                  child: Text(
                    item.accountData.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: (item.log ?? "").contains("黑名单") ? Colors.yellow[200] : null),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(5),
              constraints: const BoxConstraints(maxHeight: 150),
              child: Text(
              item.log ?? "",
              textAlign: TextAlign.left,
              style: TextStyle(color: (item.log ?? "").contains("黑名单") ? Colors.yellow[200] : null),
            ),
            ),
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