import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';

class TextInput extends StatefulWidget {
  final String label;
  final String placeHolder;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const TextInput({super.key, required this.label, this.placeHolder = "", this.onChanged, this.initialValue, this.controller});

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  late final TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: GoogleFonts.poppins(fontSize: 18.sp, color: Colors.grey)),

        Gap(10.h),

        TextField(
          controller: _internalController,
          style: GoogleFonts.poppins(fontSize: 26.sp, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: widget.placeHolder,
            hintStyle: GoogleFonts.poppins(fontSize: 20.sp, color: Colors.grey),
            isDense: true,
            contentPadding: EdgeInsets.only(bottom: 4.h),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            border: const UnderlineInputBorder(),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
