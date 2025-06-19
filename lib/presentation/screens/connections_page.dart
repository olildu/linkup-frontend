import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/data/models/chats_connection_model.dart';
import 'package:linkup/data/models/matches_connection_model.dart';
import 'package:linkup/logic/bloc/chats/chats_bloc.dart';
import 'package:linkup/logic/bloc/connections/connections_bloc.dart';
import 'package:linkup/logic/bloc/profile/own/profile_bloc.dart';
import 'package:linkup/presentation/constants/colors.dart';
import 'package:linkup/presentation/screens/chat_page.dart';
import 'package:linkup/presentation/screens/user_profile_bottom_sheet.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _YourPeoplePageState();
}

class _YourPeoplePageState extends State<ConnectionsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ConnectionsBloc>().add(ReloadChatConnectionsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text('Connections', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BlocBuilder<ConnectionsBloc, ConnectionsState>(
                builder: (context, state) {
                  if (state is ConnectionsLoaded && state.matches.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSubtitle('Your Matches', 'See your matches and connect with them'),

                        Gap(15.h),

                        SizedBox(
                          height: 80.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.matches.length,
                            cacheExtent: 20,
                            itemBuilder: (context, index) {
                              return _buildAvatar(candidate: state.matches[index]);
                            },
                          ),
                        ),

                        Gap(15.h),
                      ],
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),

              _buildTitleSubtitle('Your Chats', 'See your chats and connect with them'),

              Gap(20.h),

              Expanded(
                child: BlocBuilder<ConnectionsBloc, ConnectionsState>(
                  builder: (context, state) {
                    if (state is ConnectionsLoaded) {
                      return ListView.builder(
                        itemCount: state.chats.length,
                        padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 10.h),
                        itemBuilder: (context, index) {
                          return _buildChatTile(candidate: state.chats[index]);
                        },
                      );
                    } else {
                      return Center(
                        child: Text('No chats available', style: TextStyle(fontSize: 16.sp, color: Theme.of(context).colorScheme.onSurface)),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar({required MatchesConnectionModel candidate, double diameter = 70.0}) {
    return GestureDetector(
      onTap: () {
        log('Tapped on ${candidate.username}\'s avatar');
        showBottomSheetUserProfile(context: context, userId: candidate.id);
      },
      child: Container(
        width: diameter.w,
        height: diameter.h,
        margin: EdgeInsets.only(right: 10.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: CachedNetworkImageProvider(candidate.profilePicture), fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildChatTile({required ChatsConnectionModel candidate}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: ListTile(
        onTap: () {
          log('Tapped on chat with ${candidate.username}');
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder:
                  (context) => BlocProvider(
                    create:
                        (context) => ChatsBloc(
                          currentChatUserId: candidate.id,
                          currentUserId: (context.read<ProfileBloc>().state as ProfileLoaded).user.id,
                          chatRoomId: candidate.chatRoomId,
                        )..add(StartChatsEvent()),
                    child: ChatPage(
                      currentChatUserId: candidate.id,
                      currentUserId: (context.read<ProfileBloc>().state as ProfileLoaded).user.id,
                      userName: candidate.username,
                      userImage: candidate.profilePicture,
                      chatRoomId: candidate.chatRoomId,
                    ),
                  ),
            ),
          );
        },
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(radius: 25.r, backgroundImage: CachedNetworkImageProvider(candidate.profilePicture)),
        title: Text(
          candidate.username,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        subtitle:
            candidate.message != null
                ? Text(
                  candidate.message!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                )
                : null,
        trailing:
            candidate.unseenCounter > 0
                ? Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Text(
                    candidate.unseenCounter > 9 ? '9+' : candidate.unseenCounter.toString(),
                    style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildTitleSubtitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),

        Gap(10.h),

        Text(
          subtitle,
          style: TextStyle(fontSize: 14.sp, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey : Colors.grey.shade600),
        ),
      ],
    );
  }
}
