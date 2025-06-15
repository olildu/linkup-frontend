import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/presentation/components/chat_page/event_intro_animation.dart';

Widget buildTypingIndicator({required BuildContext context, required String userImage, required String userName}) {
  final Radius largeRadius = Radius.circular(20.r);

  final BorderRadius messageBorderRadius = BorderRadius.only(
    topLeft: largeRadius,
    topRight: largeRadius,
    bottomLeft: largeRadius,
    bottomRight: largeRadius,
  );

  final color = Color.fromARGB(255, 33, 37, 42);
  final textColor = Theme.of(context).colorScheme.onSecondaryContainer;

  return EventIntroAnimation(
    alignment: Alignment.centerLeft,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 15.r,
          backgroundImage: CachedNetworkImageProvider(userImage),
          onBackgroundImageError: (exception, stackTrace) {
            log('Error loading image: $exception');
          },
        ),
        Gap(8.w),
        Container(
          constraints: BoxConstraints(maxWidth: 0.75.sw),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(color: color, borderRadius: messageBorderRadius),
          child: Text(
            "$userName is typing...",
            style: TextStyle(fontSize: 14.sp, color: textColor, fontWeight: FontWeight.w400, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    ),
  );
}

Widget buildSeenIndicator() {
  return EventIntroAnimation(
    alignment: Alignment.centerRight,
    child: Align(alignment: Alignment.centerRight, child: Text("Seen", style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w300))),
  );
}
