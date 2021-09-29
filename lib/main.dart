import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:task/pages/home_page.dart';
import 'package:background_fetch/background_fetch.dart';

const EVENTS_KEY = "fetch_events";

//  This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  var taskId = task.taskId;
  var timeout = task.timeout;
  if (timeout) {
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }

  if (taskId == 'flutter_background_fetch') {
    
  }
} 
void main() {
  runApp(MyApp());
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}


