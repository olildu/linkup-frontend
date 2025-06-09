import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkup/presentation/constants/colors.dart';
import 'package:linkup/presentation/utils/bezier_design.dart';                                         

class MeetAt8Page extends StatefulWidget {
  const MeetAt8Page({super.key});

  @override
  State<MeetAt8Page> createState() => _MeetAt8PageState();
}

class _MeetAt8PageState extends State<MeetAt8Page> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  Container(
                    color: Colors.black,
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: RPSCustomPainter(_controller.value * 2 * pi),
                      child: child,
                    ),
                  ),
                ],
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Center(
                child: SizedBox(
                  width: constraints.maxWidth * 0.8,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A little early, aren’t you?',
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.normal,
                          color: AppColors.whiteTextColor,
                        ),
                      ),
                      Gap(10.h),
                      Text(
                        'Come back at 8 PM',
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.whiteTextColor,
                        ),
                      ),
                      Gap(10.h),
                      Text(
                        'That’s when everything starts.',
                        textAlign: TextAlign.left,
                        style: GoogleFonts.poppins(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.normal,
                          color: AppColors.whiteTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
