import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

class TextInput extends StatelessWidget {
  final String label;
  final String placeHolder;
  final String? initialValue;
  final ValueChanged<String>? onChanged;

  const TextInput({
    super.key,
    required this.label,
    this.placeHolder = "",
    this.onChanged,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            color: Colors.grey,
          ),
        ),
        
        Gap(10.h),

        TextField(
          controller: TextEditingController(text: initialValue),
          
          style: GoogleFonts.poppins(
            fontSize: 26.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: placeHolder,

            hintStyle: GoogleFonts.poppins(
              fontSize: 20.sp,
              color: Colors.grey,
            ),

            isDense: true,
            contentPadding: EdgeInsets.only(bottom: 4.h),

            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            
            border: const UnderlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
