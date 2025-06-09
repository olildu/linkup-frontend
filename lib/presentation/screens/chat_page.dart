import 'dart:async';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/data/data_parser/common/check_contains_emoji.dart';
import 'package:linkup/data/models/chat_models/message_group_model.dart';
import 'package:linkup/data/models/chat_models/message_model.dart';
import 'package:linkup/logic/bloc/chats/chats_bloc.dart';
import 'package:linkup/presentation/constants/colors.dart';
import 'package:linkup/presentation/screens/user_profile_bottom_sheet.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChatPage extends StatefulWidget {
  final int currentChatUserId;
  final int currentUserId;
  final String userName;
  final String userImage;
  final int chatRoomId;

  const ChatPage({
    super.key,
    required this.currentChatUserId,
    required this.currentUserId,
    required this.userName,
    required this.userImage,
    required this.chatRoomId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const int _messageGroupTimeThresholdMinutes = 1;

  bool _isTyping = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    _messageController.addListener(_handleTypingChange);
  }

  void _handleTypingChange() {
    final isTypingNow = _messageController.text.trim().isNotEmpty;

    if (mounted && _isTyping != isTypingNow) {
      setState(() => _isTyping = isTypingNow);
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted && isTypingNow) {
        context.read<ChatsBloc>().add(SendTypingEvent(currentChatUserId: widget.currentChatUserId));
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      final newMessage = Message(
        message: _messageController.text.trim(),
        to: widget.currentChatUserId,
        from_: widget.currentUserId,
        timestamp: DateTime.now(),
        chatRoomId: widget.chatRoomId,
      );
      context.read<ChatsBloc>().add((SendMessageEvent(message: newMessage)));
      _messageController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.minScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  MessageGroupModel _calculateMessageGroupInfo({
    required int messageIndex,
    required List<Message> messages,
  }) {
    final message = messages[messageIndex];

    int groupStart = messageIndex;
    while (groupStart > 0) {
      final prevMessage = messages[groupStart - 1];
      if (prevMessage.from_ != message.from_ ||
          message.timestamp.difference(prevMessage.timestamp).inMinutes >= _messageGroupTimeThresholdMinutes) {
        break;
      }
      groupStart--;
    }

    int groupEnd = messageIndex;
    while (groupEnd < messages.length - 1) {
      final nextMessage = messages[groupEnd + 1];
      if (nextMessage.from_ != message.from_ ||
          nextMessage.timestamp.difference(message.timestamp).inMinutes >= _messageGroupTimeThresholdMinutes) {
        break;
      }
      groupEnd++;
    }

    final groupSize = groupEnd - groupStart + 1;
    final positionInGroup = messageIndex - groupStart;
    final isFirstInGroup = messageIndex == groupStart;
    final isLastInGroup = messageIndex == groupEnd;
    final isOnlyMessageInGroup = groupSize == 1;

  final prevMessageEmoji = messageIndex > 0
      ? containsOnlyEmojis(messages[messageIndex - 1].message)
      : false;

  final nextMessageEmoji = messageIndex < messages.length - 1
      ? containsOnlyEmojis(messages[messageIndex + 1].message)
      : false;

    return MessageGroupModel(
      isFirstInGroup: isFirstInGroup,
      isLastInGroup: isLastInGroup,
      isOnlyMessageInGroup: isOnlyMessageInGroup,
      groupSize: groupSize,
      positionInGroup: positionInGroup,
      nextMessageEmoji: nextMessageEmoji,
      prevMessageEmoji: prevMessageEmoji
    );
  }

  Widget _buildMessageItem({
    required Message message,
    required BuildContext context,
    required int messageIndex,
    required List<Message> messages,
  }) {
    final bool isSentByMe = message.from_ == widget.currentUserId;
    final isOnlyEmoji = containsOnlyEmojis(message.message);

    final MessageGroupModel groupInfo = _calculateMessageGroupInfo(
      messageIndex: messageIndex,
      messages: messages,
    );

    final alignment = isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isOnlyEmoji ? Colors.transparent : isSentByMe ? AppColors.primary : Theme.of(context).colorScheme.secondaryContainer; 
    
    final textColor = isSentByMe
      ? Theme.of(context).colorScheme.onPrimaryContainer
      : Theme.of(context).colorScheme.onSecondaryContainer;

    final Radius largeRadius = Radius.circular(20.r);
    final Radius smallRadius = Radius.circular(4.r);

    // Simplified border radius logic
    BorderRadius messageBorderRadius = _getBorderRadius(
      groupInfo: groupInfo,
      isSentByMe: isSentByMe,
      isOnlyEmoji: isOnlyEmoji,
      largeRadius: largeRadius,
      smallRadius: smallRadius,
    );

    return Container(
      margin: EdgeInsets.only(
        top: groupInfo.isFirstInGroup ? 8.h : 2.h,
        bottom: 1.5.h,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: isSentByMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isSentByMe && (groupInfo.isLastInGroup || groupInfo.isOnlyMessageInGroup))
                Padding(
                  padding: EdgeInsets.only(right: 13.w, bottom: 2.h),
                  child: CircleAvatar( 
                    radius: 15.r,  
                    backgroundImage: CachedNetworkImageProvider(
                      widget.userImage,
                    ),
                    onBackgroundImageError: (exception, stackTrace) {
                      log('Error loading image: $exception');
                    },
                  ),
                )
              else if (!isSentByMe)...[
                Padding(
                  padding: EdgeInsets.only(right: 13.w, bottom: 2.h),
                  child: SizedBox(
                    width: 30.r, 
                    height: 30.r,
                  ),
                ),
              ],

              VisibilityDetector(
                key: Key(message.id.toString()),
                onVisibilityChanged: (info) {
                  if (!isSentByMe && !message.isSeen) {
                    log(info.toString());
                    context.read<ChatsBloc>().add(MarkMessageAsSeenEvent(messageId: message.id!));
                  }
                },
                child: Container(  
                  constraints: BoxConstraints( 
                    maxWidth: 0.75.sw, 
                  ),
                  padding: isOnlyEmoji
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ), 
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: messageBorderRadius,
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontSize: isOnlyEmoji ? 35.sp : 14.sp,
                      color: isOnlyEmoji ? null : textColor, 
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Separate method for cleaner border radius logic
  BorderRadius _getBorderRadius({
    required MessageGroupModel groupInfo,
    required bool isSentByMe,
    required bool isOnlyEmoji,
    required Radius largeRadius,
    required Radius smallRadius,
  }) {
    // For emoji-only messages, always use full rounded corners
    if (isOnlyEmoji) {
      return BorderRadius.all(largeRadius);
    }

    // For single messages (not part of a group), use full rounded corners
    if (groupInfo.isOnlyMessageInGroup) {
      return BorderRadius.all(largeRadius);
    }

    // Handle special cases where adjacent messages are emojis
    final shouldUseFullRadius = _shouldUseFullRadius(groupInfo);
    if (shouldUseFullRadius) {
      return BorderRadius.all(largeRadius);
    }

    // Regular grouping logic
    if (isSentByMe) {
      return _getSentMessageBorderRadius(groupInfo, largeRadius, smallRadius);
    } else {
      return _getReceivedMessageBorderRadius(groupInfo, largeRadius, smallRadius);
    }
  }

  // Check if message should have full rounded corners due to emoji neighbors
  bool _shouldUseFullRadius(MessageGroupModel groupInfo) {
    // If both adjacent messages are emojis
    if (groupInfo.prevMessageEmoji && groupInfo.nextMessageEmoji) {
      return true;
    }
    
    // If previous message is emoji and this is the last in group
    if (groupInfo.prevMessageEmoji && groupInfo.isLastInGroup) {
      return true;
    }
    
    // If next message is emoji and this is the first in group
    if (groupInfo.nextMessageEmoji && groupInfo.isFirstInGroup) {
      return true;
    }
    
    return false;
  }

  // Border radius for messages sent by current user (right side)
  BorderRadius _getSentMessageBorderRadius(
    MessageGroupModel groupInfo,
    Radius largeRadius,
    Radius smallRadius,
  ) {
    if (groupInfo.isFirstInGroup) {
      return BorderRadius.only(
        topLeft: largeRadius,
        topRight: largeRadius,
        bottomLeft: largeRadius,
        bottomRight: smallRadius, // Tail on bottom-right
      );
    } else if (groupInfo.isLastInGroup) {
      return BorderRadius.only(
        topLeft: largeRadius,
        topRight: smallRadius, // Connected to message above
        bottomLeft: largeRadius,
        bottomRight: largeRadius, // Rounded tail
      );
    } else {
      // Middle message
      return BorderRadius.only(
        topLeft: largeRadius,
        topRight: smallRadius, // Connected to message above
        bottomLeft: largeRadius,
        bottomRight: smallRadius, // Connected to message below
      );
    }
  }

  // Border radius for received messages (left side)
  BorderRadius _getReceivedMessageBorderRadius(
  MessageGroupModel groupInfo,
  Radius largeRadius,
  Radius smallRadius,
) {
  if (groupInfo.isFirstInGroup) {
    return BorderRadius.only(
      topLeft: largeRadius,
      topRight: largeRadius,
      bottomLeft: smallRadius, // Tail on bottom-left
      bottomRight: largeRadius,
    );
  } else if (groupInfo.isLastInGroup) {
    return BorderRadius.only(
      topLeft: smallRadius, // Connected to message above
      topRight: largeRadius,
      bottomLeft: largeRadius, // Rounded tail
      bottomRight: largeRadius,
    );
  } else {
    // Middle message
    return BorderRadius.only(
      topLeft: smallRadius, // Connected to message above
      topRight: largeRadius,
      bottomLeft: smallRadius, // Connected to message below
      bottomRight: largeRadius,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            showBottomSheetUserProfile(
              context: context,
              userId: widget.currentChatUserId,
              showChatButton: false,
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 15.r,
                backgroundImage: CachedNetworkImageProvider(widget.userImage),
                onBackgroundImageError: (exception, stackTrace) {
                  log('Error loading image: $exception');
                },
              ),
              Gap(10.w),
              Text(
                widget.userName,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onSurface,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: BlocBuilder<ChatsBloc, ChatsState>(
          builder: (context, state) {
            if (state is ChatsLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            } else if (state is ChatsError) {
              return Center(
                child: Text(
                  'Error loading messages',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16.sp,
                  ),
                ),
              );
            } else if (state is ChatsLoaded) {
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.only(
                        top: 10.h,
                        bottom: 10.h,
                      ),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final chronologicalIndex = state.messages.length - 1 - index;
                        final message = state.messages[chronologicalIndex];
        
                        return _buildMessageItem(
                          message: message,
                          context: context,
                          messageIndex: chronologicalIndex,
                          messages: state.messages,
                        );
                      },
                    ),
                  ),
                  if (state.messages.isNotEmpty &&
                      ((state.otherUserSeenMsg && state.messages.last.from_ == widget.currentUserId) ||
                        (state.messages.last.isSeen && state.messages.last.from_ == widget.currentUserId)))

                    _buildSeenIndicator(),

                  if (state.isTyping)
                    _buildTypingIndicator(),
        
                  _buildMessageInputArea(context),
                ],
              );
            } else {
              return Center(
                child: Text(
                  'No messages yet',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 16.sp,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTypingChange);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 5,
            spreadRadius: -1,
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 120.h),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.outline,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.r),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1.5,
                      ),
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
                return ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _isTyping
                  ? Material(
                      key: const ValueKey('send_button'),
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(25.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25.r),
                        onTap: _sendMessage,
                        child: Padding(
                          padding: EdgeInsets.all(10.r),
                          child: Icon(
                            Icons.send_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 22.sp,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(50.r),
                      ),
                      child: Row(
                        key: const ValueKey('mic_camera_icons'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.mic_none_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24.sp,
                            ),
                            onPressed: () {
                              // TODO: Implement voice message functionality
                              log("Mic button pressed");
                            },
                            tooltip: 'Send voice message',
                            padding: EdgeInsets.all(10.r),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.camera_alt_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24.sp,
                            ),
                            onPressed: () {
                              // TODO: Implement send image/video functionality
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

  Widget _buildTypingIndicator() {
    final Radius largeRadius = Radius.circular(20.r);

    final BorderRadius messageBorderRadius = BorderRadius.only(
      topLeft: largeRadius,
      topRight: largeRadius,
      bottomLeft: largeRadius,
      bottomRight: largeRadius,
    );

    final color = Theme.of(context).colorScheme.secondaryContainer;
    final textColor = Theme.of(context).colorScheme.onSecondaryContainer;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        CircleAvatar(
          radius: 15.r,
          backgroundImage: CachedNetworkImageProvider(widget.userImage),
          onBackgroundImageError: (exception, stackTrace) {
            log('Error loading image: $exception');
          },
        ),
        Gap(8.w),
        Container(
          constraints: BoxConstraints(
            maxWidth: 0.75.sw,
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: messageBorderRadius,
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            "${widget.userName} is typing...",
            style: TextStyle(
              fontSize: 14.sp,
              color: textColor,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeenIndicator() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        "Seen",
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}