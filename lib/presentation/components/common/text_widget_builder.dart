import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTextWidget extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines; // Change: Keep this nullable
  final TextOverflow? overflow;

  const CustomTextWidget(
    this.text, {
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w400,
    this.color = Colors.black,
    this.textAlign = TextAlign.left,
    this.maxLines,
    this.overflow, // Fix: Remove default ellipsis here
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: (fontSize ?? 14).sp, fontWeight: fontWeight, color: color),
      textAlign: textAlign,
      maxLines: maxLines, // If null, it will wrap infinitely
      overflow: overflow, // If null, it defaults to clip/wrap
    );
  }
}
