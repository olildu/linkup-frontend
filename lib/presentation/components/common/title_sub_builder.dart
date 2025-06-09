  import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/presentation/constants/colors.dart';

class BuildTitleSubtitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const BuildTitleSubtitle({
    required this.title,
    required this.subtitle,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        
        Gap(10.h),

        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.notSelected
              : const Color.fromARGB(255, 141, 141, 141),
          ),
        ),
      ],
    );

  }
}