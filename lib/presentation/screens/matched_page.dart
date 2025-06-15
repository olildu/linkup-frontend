import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:linkup/data/http_services/chat_http_services/chat_http_services.dart';
import 'package:linkup/data/models/matches_connection_model.dart';
import 'package:linkup/logic/bloc/chats/chats_bloc.dart';
import 'package:linkup/logic/bloc/matches/matches_bloc.dart';
import 'package:linkup/logic/bloc/profile/own/profile_bloc.dart';
import 'package:linkup/presentation/components/signup_page/button_builder.dart';
import 'package:linkup/presentation/components/signup_page/page_title_builder_component.dart';
import 'package:linkup/presentation/screens/chat_page.dart';

class MatchedPage extends StatefulWidget {
  final MatchesConnectionModel matchUser;
  final bool meet8State;

  const MatchedPage({super.key, required this.matchUser, this.meet8State = false});

  @override
  State<MatchedPage> createState() => _MatchedPageState();
}

class _MatchedPageState extends State<MatchedPage> {
  final double _rotationAngle = 0.1;
  final double _imageWidth = 150.w;
  final double _imageHeight = 250.h;
  final double _offset = 40.h;

  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;

  @override
  void initState() {
    super.initState();
    _confettiControllerLeft = ConfettiController(duration: const Duration(seconds: 3));
    _confettiControllerRight = ConfettiController(duration: const Duration(seconds: 3));

    Future.delayed(Duration(milliseconds: 300), () async {
      await Haptics.vibrate(HapticsType.success);
      _confettiControllerLeft.play();
      _confettiControllerRight.play();
    });
  }

  @override
  void dispose() {
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.meet8State ? Colors.transparent : Theme.of(context).colorScheme.onSurface,
      appBar:
          widget.meet8State
              ? null
              : AppBar(
                leading: IconButton(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface, size: 30.sp),
                  onPressed: () {
                    context.read<MatchesBloc>().add(ClearMatchUserEvent());
                    Navigator.pop(context, true);
                  },
                ),
              ),

      body: Padding(
        padding: EdgeInsets.only(left: 20.w, right: 20.w, top: widget.meet8State ? 40.h : 110.h, bottom: 70.h),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: _imageBuilder(
                        imageUrl: (context.read<ProfileBloc>().state as ProfileLoaded).user.profilePicture,
                        offsetX: -_offset,
                        angle: -_rotationAngle,
                      ),
                    ),
                    _imageBuilder(imageUrl: widget.matchUser.profilePicture, offsetX: _offset, angle: _rotationAngle),
                  ],
                ),
                Gap(50.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: PageTitle(
                    inputText:
                        widget.meet8State
                            ? "Congratulations!\n${widget.matchUser.username} and you have been matched"
                            : "Congratulations!\n${widget.matchUser.username} and you like each other",
                    highlightWord: widget.matchUser.username,
                  ),
                ),

                if (!widget.meet8State) ...[
                  const Spacer(),
                  ButtonBuilder(
                    text: "Start Messaging",
                    onPressed: () async {
                      final currentUserId = (context.read<ProfileBloc>().state as ProfileLoaded).user.id;
                      final status = await ChatHttpServices().startChat(chatUserId: widget.matchUser.id);

                      if (status == 0) {
                        Navigator.of(context).pushReplacement(
                          CupertinoPageRoute(
                            builder:
                                (ctx) => BlocProvider(
                                  create:
                                      (ctx) =>
                                          ChatsBloc(currentChatUserId: widget.matchUser.id, currentUserId: currentUserId, chatRoomId: -1)
                                            ..add(StartChatsEvent()),
                                  child: ChatPage(
                                    currentChatUserId: widget.matchUser.id,
                                    currentUserId: currentUserId,
                                    userName: widget.matchUser.username,
                                    userImage: widget.matchUser.profilePicture,
                                    // TODO: Replace with actual chat room ID
                                    chatRoomId: 10,
                                  ),
                                ),
                          ),
                        );
                      }
                    },
                    height: 60.h,
                  ),
                ],
              ],
            ),

            _confettiBuilder(controller: _confettiControllerLeft, alignment: Alignment.centerLeft, blastDirection: 0),

            _confettiBuilder(controller: _confettiControllerRight, alignment: Alignment.centerRight, blastDirection: pi),
          ],
        ),
      ),
    );
  }

  Widget _imageBuilder({required String imageUrl, required double offsetX, required double angle}) {
    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: _imageWidth,
          height: _imageHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(4, 4))],
            image: DecorationImage(image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _confettiBuilder({required ConfettiController controller, required Alignment alignment, required double blastDirection}) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.07,
      left: alignment == Alignment.centerLeft ? 0 : null,
      right: alignment == Alignment.centerRight ? 0 : null,
      child: ConfettiWidget(
        confettiController: controller,
        blastDirection: blastDirection,
        emissionFrequency: 0.05,
        numberOfParticles: 5,
        maxBlastForce: 20,
        minBlastForce: 10,
        gravity: 0.1,
        particleDrag: 0.05,
        colors: const [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.yellow],
      ),
    );
  }
}
