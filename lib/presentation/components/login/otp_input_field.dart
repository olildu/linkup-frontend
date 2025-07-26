import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class OtpInputField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool hasError;

  const OtpInputField({super.key, required this.label, required this.hintText, required this.controller, this.hasError = false});

  @override
  Widget build(BuildContext context) {
    final Color borderColor = hasError ? const Color.fromARGB(255, 244, 21, 5) : Colors.grey[300]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.black)),
        Gap(6.h),
        TextField(
          obscureText: true,
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black, letterSpacing: 4.w),
          decoration: InputDecoration(
            counterText: '',
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.r),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.blue),
            ),
          ),
        ),
      ],
    );
  }
}
