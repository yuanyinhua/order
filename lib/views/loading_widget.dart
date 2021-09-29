import 'package:flutter/cupertino.dart';

class LoadingWidget extends StatelessWidget {
  LoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: CupertinoActivityIndicator(
      animating: true,
      radius: 10,
    ));
  }
}
