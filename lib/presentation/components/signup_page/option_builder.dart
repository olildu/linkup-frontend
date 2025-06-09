import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkup/presentation/constants/colors.dart';

class OptionBuilder extends StatefulWidget {
  final List options;
  final Function onChanged;
  final int currentIndex;
  final String? currentOption;
  final double textSize;

  const OptionBuilder({
    super.key,
    required this.options,
    required this.onChanged,
    this.currentIndex = -1,
    this.currentOption,
    this.textSize = 16, // Default value
  });

  @override
  State<OptionBuilder> createState() => _OptionBuilderState();
}

class _OptionBuilderState extends State<OptionBuilder> {
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.currentOption != null) {
      final index = widget.options.indexOf(widget.currentOption);
      if (index != -1) {
        _currentIndex = index;
      } else {
        _currentIndex = widget.currentIndex;
      }
    } else {
      _currentIndex = widget.currentIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(widget.options.length, (index) {
            return GestureDetector(
              onTap: () {
                widget.onChanged(widget.options[index]);
                setState(() {
                  _currentIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 15.h),
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? AppColors.primary
                      : AppColors.notSelected,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  widget.options[index],
                  style: GoogleFonts.poppins(
                    fontSize: widget.textSize,
                    color: AppColors.whiteTextColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
