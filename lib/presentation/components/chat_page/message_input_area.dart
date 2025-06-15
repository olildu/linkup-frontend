import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class MessageInputArea extends StatelessWidget {
  final TextEditingController messageController;
  final bool isTyping;
  final Function() sendMessage;
  const MessageInputArea({super.key, required this.messageController, required this.isTyping, required this.sendMessage});

  @override
  Widget build(BuildContext context) {
    print("Is typing in message input area : $isTyping");

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(offset: const Offset(0, -2), blurRadius: 5, spreadRadius: -1, color: Colors.black.withValues(alpha: 0.08))],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 120.h),
                child: TextField(
                  controller: messageController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 15.sp, color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.outline,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.r), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            Gap(8.w),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
              },
              child:
                  isTyping
                      ? Material(
                        key: const ValueKey('send_button'),
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(25.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25.r),
                          onTap: sendMessage,
                          child: Padding(
                            padding: EdgeInsets.all(10.r),
                            child: Icon(Icons.send_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 22.sp),
                          ),
                        ),
                      )
                      : Container(
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.outline, borderRadius: BorderRadius.circular(50.r)),
                        child: Row(
                          key: const ValueKey('mic_camera_icons'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.mic_none_rounded, color: Theme.of(context).colorScheme.primary, size: 24.sp),
                              onPressed: () {
                                log("Mic button pressed");
                              },
                              tooltip: 'Send voice message',
                              padding: EdgeInsets.all(10.r),
                            ),
                            IconButton(
                              icon: Icon(Icons.camera_alt_outlined, color: Theme.of(context).colorScheme.primary, size: 24.sp),
                              onPressed: () {
                                log("Camera button pressed");
                              },
                              tooltip: 'Send image/video',
                              padding: EdgeInsets.all(10.r),
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
