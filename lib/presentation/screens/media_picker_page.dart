import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/logic/bloc/camera/camera_bloc.dart';

class MediaPickerPage extends StatelessWidget {
  const MediaPickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    void shouldPop(CameraState state) {
      if (state is MediaCaptureSuccess) {
        context.read<CameraBloc>().add(CameraInitEvent());
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<CameraBloc, CameraState>(
        builder: (context, state) {
          return PopScope(
            canPop: state is MediaCaptureSuccess ? false : true,
            onPopInvokedWithResult: (didPop, result) {
              shouldPop(state);
            },
            child: Hero(
              tag: 'camera-hero',
              child: Padding(
                padding: EdgeInsets.only(top: 50.h),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.r),
                        child: Container(
                          color: Colors.black,
                          child: Builder(
                            builder: (context) {
                              if (state is CameraLoaded) {
                                return AspectRatio(
                                  aspectRatio: state.controller.value.aspectRatio,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: state.controller.value.previewSize!.height,
                                      height: state.controller.value.previewSize!.width,
                                      child: CameraPreview(state.controller),
                                    ),
                                  ),
                                );
                              } else if (state is CameraLoading) {
                                return SizedBox.shrink();
                              } else if (state is CameraError) {
                                return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                              } else if (state is MediaCaptureSuccess) {
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: AspectRatio(
                                        aspectRatio: state.aspectRatio,
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: state.height,
                                            height: state.width,
                                            child: Transform.flip(
                                              flipX: state.takenFromFrontCamera ? true : false,
                                              child: Image.file(File(state.mediaFile.path)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    Positioned(
                                      top: 16.h,
                                      left: 16.w,
                                      child: IconButton(
                                        icon: Icon(Icons.close_rounded, color: Colors.white, size: 30.sp),
                                        onPressed: () {
                                          context.read<CameraBloc>().add(CameraInitEvent());
                                        },
                                        style: ButtonStyle(
                                          backgroundColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.4)),
                                          shape: WidgetStateProperty.all(const CircleBorder()),
                                          padding: WidgetStateProperty.all(EdgeInsets.all(6.r)),
                                        ),
                                      ),
                                    ),

                                    Positioned(
                                      top: 16.h,
                                      right: 16.w,
                                      child: IconButton(
                                        icon: Icon(Icons.download_rounded, color: Colors.white, size: 30.sp),
                                        onPressed: () async {
                                          context.read<CameraBloc>().add(CameraSavePictureEvent(imageFile: state.mediaFile));
                                        },
                                        style: ButtonStyle(
                                          backgroundColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.4)),
                                          shape: WidgetStateProperty.all(const CircleBorder()),
                                          padding: WidgetStateProperty.all(EdgeInsets.all(6.r)),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            },
                          ),
                        ),
                      ),
                    ),

                    Builder(
                      builder: (context) {
                        if (state is MediaCaptureSuccess) {
                          return Align(
                            alignment: Alignment.bottomRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop(File(state.mediaFile.path));
                              },
                              child: Container(
                                margin: EdgeInsets.only(top: 10.h, bottom: 20.h, right: 5.w),
                                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(30.r),
                                    bottomLeft: Radius.circular(30.r),
                                    topRight: Radius.circular(30.r),
                                    bottomRight: Radius.circular(30.r),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 13.r,
                                      backgroundImage: NetworkImage("https://picsum.photos/seed/86f4c11b-41c8-4c6f-b263-9a6e70e6aa2a/200/200"),
                                    ),

                                    Gap(8.w),

                                    Text("Send", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildIconButton(
                                  icon: Icons.image_rounded,
                                  onPressed: () async {
                                    context.read<CameraBloc>().add(CameraGalleryPictureEvent());
                                  },
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (state is CameraLoaded) {
                                      context.read<CameraBloc>().add(CameraTakePictureEvent());
                                    }
                                  },
                                  child: Container(
                                    width: 70.w,
                                    height: 70.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 56.w,
                                        height: 56.w,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
                                      ),
                                    ),
                                  ),
                                ),
                                _buildIconButton(
                                  icon: Icons.sync_rounded,
                                  onPressed: () {
                                    context.read<CameraBloc>().add(CameraSwitchEvent());
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade800, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, size: 30.sp, color: Colors.white), onPressed: onPressed, splashRadius: 28.r),
    );
  }
}
