import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/data/data_parser/common/check_contains_emoji.dart';
import 'package:linkup/data/models/chat_models/message_group_model.dart';
import 'package:linkup/data/models/chat_models/message_model.dart';
import 'package:linkup/logic/bloc/chats/chats_bloc.dart';
import 'package:linkup/logic/bloc/connections/connections_bloc.dart';
import 'package:linkup/presentation/components/chat_page/calculate_border_shape.dart';
import 'package:linkup/presentation/components/chat_page/message_input_area.dart';
import 'package:linkup/presentation/components/chat_page/minor_event_widgets.dart';
import 'package:linkup/presentation/constants/colors.dart';
import 'package:linkup/presentation/screens/full_screen_image_page.dart';
import 'package:linkup/presentation/screens/user_profile_bottom_sheet.dart';
import 'package:linkup/presentation/utils/blurhash_util.dart';
import 'package:octo_image/octo_image.dart';
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
  bool _initalSeenMarked = false;

  final GlobalKey<AnimatedListState> _animatedListKey = GlobalKey<AnimatedListState>();
  List<Message> _currentMessages = [];

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

  @override
  void dispose() {
    _messageController.removeListener(_handleTypingChange);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTypingChange() {
    final isTypingNow = _messageController.text.trim().isNotEmpty;

    if (mounted) {
      setState(() => _isTyping = isTypingNow);
    }

    if (mounted && isTypingNow) {
      context.read<ChatsBloc>().add(SendTypingEvent(currentChatUserId: widget.currentChatUserId));
    }
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
          _scrollController.animateTo(_scrollController.position.minScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }
  }

  MessageGroupModel _calculateMessageGroupInfo({required int messageIndex, required List<Message> messages}) {
    final message = messages[messageIndex];

    int groupStart = messageIndex;
    while (groupStart > 0) {
      final prevMessage = messages[groupStart - 1];
      if (prevMessage.from_ != message.from_ || message.timestamp.difference(prevMessage.timestamp).inMinutes >= _messageGroupTimeThresholdMinutes) {
        break;
      }
      groupStart--;
    }

    int groupEnd = messageIndex;
    while (groupEnd < messages.length - 1) {
      final nextMessage = messages[groupEnd + 1];
      if (nextMessage.from_ != message.from_ || nextMessage.timestamp.difference(message.timestamp).inMinutes >= _messageGroupTimeThresholdMinutes) {
        break;
      }
      groupEnd++;
    }

    final groupSize = groupEnd - groupStart + 1;
    final positionInGroup = messageIndex - groupStart;
    final isFirstInGroup = messageIndex == groupStart;
    final isLastInGroup = messageIndex == groupEnd;
    final isOnlyMessageInGroup = groupSize == 1;

    final prevMessageEmoji = messageIndex > 0 ? containsOnlyEmojis(messages[messageIndex - 1].message) : false;

    final nextMessageEmoji = messageIndex < messages.length - 1 ? containsOnlyEmojis(messages[messageIndex + 1].message) : false;

    return MessageGroupModel(
      isFirstInGroup: isFirstInGroup,
      isLastInGroup: isLastInGroup,
      isOnlyMessageInGroup: isOnlyMessageInGroup,
      groupSize: groupSize,
      positionInGroup: positionInGroup,
      nextMessageEmoji: nextMessageEmoji,
      prevMessageEmoji: prevMessageEmoji,
    );
  }

  Widget _buildMessageItem({required Message message, required BuildContext context, required int messageIndex, required List<Message> messages}) {
    final bool isSentByMe = message.from_ == widget.currentUserId;
    final isOnlyEmoji = containsOnlyEmojis(message.message);

    final MessageGroupModel groupInfo = _calculateMessageGroupInfo(messageIndex: messageIndex, messages: messages);

    final alignment = isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color =
        isOnlyEmoji
            ? Colors.transparent
            : isSentByMe
            ? AppColors.primary
            : Color.fromARGB(255, 33, 37, 42);

    final textColor = isSentByMe ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSecondaryContainer;

    final Radius largeRadius = Radius.circular(20.r);
    final Radius smallRadius = Radius.circular(4.r);

    BorderRadius messageBorderRadius = getBorderRadius(
      groupInfo: groupInfo,
      isSentByMe: isSentByMe,
      isOnlyEmoji: isOnlyEmoji,
      largeRadius: largeRadius,
      smallRadius: smallRadius,
    );

    return Container(
      margin: EdgeInsets.only(top: groupInfo.isFirstInGroup ? 8.h : 2.h, bottom: 1.5.h),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isSentByMe && (groupInfo.isLastInGroup || groupInfo.isOnlyMessageInGroup))
                Padding(
                  padding: EdgeInsets.only(right: 13.w, bottom: 2.h),
                  child: CircleAvatar(
                    radius: 15.r,
                    backgroundImage: CachedNetworkImageProvider(widget.userImage),
                    onBackgroundImageError: (exception, stackTrace) {
                      log('Error loading image: $exception');
                    },
                  ),
                )
              else if (!isSentByMe) ...[
                Padding(padding: EdgeInsets.only(right: 13.w, bottom: 2.h), child: SizedBox(width: 30.r, height: 30.r)),
              ],
              VisibilityDetector(
                key: Key(message.id.toString()),
                onVisibilityChanged: (info) {
                  if (!isSentByMe && !message.isSeen) {
                    final int lastMessageID = messages.last.id!;
                    final int currentSeenMessageID = message.id!;
                    final int seenDiff = lastMessageID - currentSeenMessageID;

                    context.read<ChatsBloc>().add(MarkMessageAsSeenEvent(messageId: message.id!));
                    if (_initalSeenMarked) {
                      context.read<ConnectionsBloc>().add(MarkMessagesSeenEvent(chatRoomId: widget.chatRoomId, decrementCounterTo: seenDiff));
                    }
                  }
                },
                child: Builder(
                  builder: (context) {
                    if (message.media != null) {
                      final mediaMetaData = message.media!.metadata;

                      final String imageUrl = mediaMetaData["file_url"];
                      final double height = mediaMetaData["height"];
                      final double width = mediaMetaData["width"];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => FullScreenImageScreen(imagePath: imageUrl)));
                        },
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 0.6.sw, maxHeight: 250.h),
                          width: height,
                          height: width,
                          decoration: BoxDecoration(borderRadius: messageBorderRadius),
                          clipBehavior: Clip.antiAlias,
                          child: OctoImage(
                            image: CachedNetworkImageProvider(imageUrl, maxHeight: height.toInt(), maxWidth: width.toInt()),
                            placeholderBuilder: blurHash(mediaMetaData["blurhash"]).placeholderBuilder,
                            errorBuilder: OctoError.icon(color: Colors.red),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    } else {
                      return Container(
                        constraints: BoxConstraints(maxWidth: 0.75.sw),
                        padding: isOnlyEmoji ? EdgeInsets.zero : EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(color: color, borderRadius: messageBorderRadius),
                        child: Text(
                          message.message,
                          style: TextStyle(fontSize: isOnlyEmoji ? 35.sp : 14.sp, color: isOnlyEmoji ? null : textColor, fontWeight: FontWeight.w400),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMedia(File imageFile) {
    context.read<ChatsBloc>().add(UploadMediaEvent(mediaType: MessageType.image, file: imageFile));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            showBottomSheetUserProfile(context: context, userId: widget.currentChatUserId, showChatButton: false);
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
              Text(widget.userName, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: BlocConsumer<ChatsBloc, ChatsState>(
          listener: (context, state) {
            if (state is ChatsLoaded) {
              if (state.messages.length > _currentMessages.length) {
                final int newItemsCount = state.messages.length - _currentMessages.length;
                for (int i = 0; i < newItemsCount; i++) {
                  _animatedListKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 300));
                }
              }
              _currentMessages = List.from(state.messages);
            }
          },
          builder: (context, state) {
            if (state is ChatsLoading) {
              return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
            } else if (state is ChatsError) {
              return Center(child: Text('Error loading messages', style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16.sp)));
            } else if (state is ChatsLoaded) {
              if (_currentMessages.isEmpty && state.messages.isNotEmpty) {
                _currentMessages = List.from(state.messages);
              }
              if (!_initalSeenMarked) {
                context.read<ConnectionsBloc>().add(MarkMessagesSeenEvent(chatRoomId: widget.chatRoomId, decrementCounterTo: 0));
                _initalSeenMarked = true;
              }

              return Column(
                children: [
                  Expanded(
                    child: AnimatedList(
                      key: _animatedListKey,
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.only(top: 10.h, bottom: 10.h),
                      initialItemCount: _currentMessages.length,
                      itemBuilder: (context, index, animation) {
                        final chronologicalIndex = _currentMessages.length - 1 - index;
                        final message = _currentMessages[chronologicalIndex];

                        return SlideTransition(
                          position: Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(animation),
                          child: _buildMessageItem(message: message, context: context, messageIndex: chronologicalIndex, messages: _currentMessages),
                        );
                      },
                    ),
                  ),
                  if (state.messages.isNotEmpty &&
                      state.messages.last.from_ == widget.currentUserId &&
                      (state.otherUserSeenMsg || state.messages.last.isSeen))
                    Builder(
                      builder: (context) {
                        return buildSeenIndicator();
                      },
                    ),

                  if (state.isTyping) buildTypingIndicator(context: context, userImage: widget.userImage, userName: widget.userName),

                  MessageInputArea(messageController: _messageController, isTyping: _isTyping, sendMessage: _sendMessage, handleMedia: _handleMedia),
                ],
              );
            } else {
              return Center(
                child: Text(
                  'No messages yet',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 16.sp),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
