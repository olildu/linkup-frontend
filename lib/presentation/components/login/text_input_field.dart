import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class TextInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback? toggleObscure;
  final bool hasError;

  const TextInputField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.toggleObscure,
    this.hasError = false,
  });

  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<TextInputField> {
  late Color borderColor = widget.hasError ? const Color.fromARGB(255, 244, 21, 5) : Colors.grey[300]!;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          // Changed color to Colors.black for a darker label
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        Gap(8.h),
        TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          // Added style to TextField to make the input text darker
          style: TextStyle(
            color: Colors.black, // Darker color for the input text
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: widget.hasError ? Colors.red : Colors.blue),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            suffixIcon:
                widget.toggleObscure != null
                    ? IconButton(
                      icon: Icon(widget.obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey[600]),
                      onPressed: widget.toggleObscure,
                    )
                    : null,
          ),
        ),
      ],
    );
  }
}
