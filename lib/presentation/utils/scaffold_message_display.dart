      
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showScaffoldMessage({
  required BuildContext context,
  required String message,
  Color backgroundColor = Colors.red,
  Color textColor = Colors.white,
  double fontSize = 16,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: textColor,
          fontSize: (fontSize).sp,
        ),
      ),
      backgroundColor: backgroundColor,
    ),
  );
}