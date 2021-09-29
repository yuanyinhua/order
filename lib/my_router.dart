import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:task/pages/home_page.dart';

import 'package:task/pages/query_available_page.dart';

class MyRouter {
  static const queryPage = 'app://query';

  Widget _getPage(String url, dynamic params) {
    if (url == queryPage) {
      return QueryAvailablePage();
    }
    return HomePage();
  }

  MyRouter.pushNoParams(BuildContext context, String url) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return _getPage(url, null);
    }));
  }

  MyRouter.push(BuildContext context, String url, dynamic params) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return _getPage(url, params);
    }));
  }
}