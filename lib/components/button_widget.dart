import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? text;
  ButtonWidget({
    Key? key,
    this.text,
    required this.onPressed,
    this.onLongPress,
  }) : super(key: key);

  final style = ButtonStyle(
      backgroundColor:
          MaterialStateProperty.all(const Color.fromRGBO(208, 208, 208, 1)));
  final textStyle = const TextStyle(color: Colors.black87, fontSize: 12);
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: style,
        onPressed: onPressed,
        child: SizedBox(
            child: Text(
          text ?? "",
          style: textStyle,
        )));
  }
}
