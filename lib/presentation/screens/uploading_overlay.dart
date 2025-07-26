import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class UploadingOverlay extends StatefulWidget {
  const UploadingOverlay({super.key});

  @override
  State<UploadingOverlay> createState() => _UploadingOverlayState();
}

class _UploadingOverlayState extends State<UploadingOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: Scaffold(
        backgroundColor: Colors.green.shade600,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48.w,
                  height: 48.w,
                  child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 4.w),
                ),
                Gap(40.h),
                Text('Uploading...', style: TextStyle(fontSize: 20.sp, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 1.2.w)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
