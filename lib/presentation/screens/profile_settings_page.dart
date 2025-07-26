import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/data/models/candidate_info_model.dart';
import 'package:linkup/data/models/update_metadata_model.dart';
import 'package:linkup/data/models/user_model.dart';
import 'package:linkup/logic/bloc/profile/own/profile_bloc.dart';
import 'package:linkup/presentation/components/common/image_picker_builder.dart';
import 'package:linkup/presentation/components/common/text_field_builder.dart';
import 'package:linkup/presentation/components/common/title_sub_builder.dart';
import 'package:linkup/presentation/components/signup_page/button_builder.dart';
import 'package:linkup/presentation/constants/colors.dart';
import 'package:linkup/presentation/screens/settings_page.dart';
import 'package:linkup/presentation/screens/singup_flow_page.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  bool aboutMeChanged = false;
  late String aboutMeContent;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          'Profile Settings',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsPage()));
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileError) {
                return Center(
                  child: Text('Error loading profile settings', style: TextStyle(fontSize: 16.sp, color: Theme.of(context).colorScheme.error)),
                );
              } else if (state is ProfileLoaded) {
                final UserModel user = state.user;
                final candidateInformation = CandidateInfoModel.fromUserModel(user);
                aboutMeContent = user.about!;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BuildTitleSubtitle(title: 'Profile Picture', subtitle: 'Choose a profile picture'),
                      Gap(20.h),
                      ImagePickerBuilder(
                        maxImages: 6,
                        onImagesChanged: (e) {
                          log(e.first.name);
                        },
                        initialImages: user.photos!,
                      ),

                      Gap(20.h),
                      BuildTitleSubtitle(title: 'About Me', subtitle: 'Tell us about yourself'),
                      Gap(20.h),
                      StatefulBuilder(
                        builder: (context, internalSetState) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextFieldBuilder(
                                hintText: 'Write something about yourself',
                                initialValue: aboutMeContent,
                                maxLines: 3,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(10.r)),
                                  borderSide: BorderSide(color: AppColors.notSelected),
                                ),
                                onChanged: (value) {
                                  internalSetState(() {
                                    aboutMeChanged = value.trim().isNotEmpty;
                                    aboutMeContent = value;
                                  });
                                },
                              ),

                              if (aboutMeChanged) ...[
                                Gap(20.h),

                                ButtonBuilder(
                                  text: "Save",
                                  width: 70.w,
                                  isFullWidth: false,
                                  borderRadius: 10.r,
                                  padding: EdgeInsets.zero,
                                  height: 50.h,
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    context.read<ProfileBloc>().add(ProfileUpdateEvent(userUpdatedModel: UpdateMetadataModel(about: aboutMeContent)));
                                    setState(() {
                                      aboutMeChanged = false;
                                    });
                                  },
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      Gap(20.h),

                      BuildTitleSubtitle(title: 'Your Information', subtitle: 'Select or update your information'),
                      Gap(20.h),
                      Column(
                        children:
                            candidateInformation.asIconMap(showGender: false).entries.map((entry) {
                              final icon = entry.value['icon'] as IconData;
                              final value = entry.value['value'];
                              final title = entry.value['title'] as String;
                              final index = entry.value['index'] as int;

                              return _buildOptions(icon, title, value, index, candidateInformation);
                            }).toList(),
                      ),
                    ],
                  ),

                  //gender
                  //currentlyStaying
                  //hometown
                );
              } else {
                return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(IconData icon, String title, String? data, int index, dynamic optionsData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => SingupFlowPage(initialIndex: index, initialData: optionsData.toJson())));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 30.h),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: Theme.of(context).colorScheme.onSurface),
            Gap(10.w),
            Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            const Spacer(),
            Text(
              data ?? "None",
              style: TextStyle(fontSize: 14.sp, color: Theme.of(context).brightness == Brightness.dark ? AppColors.notSelected : Colors.black),
            ),

            Gap(10.w),

            Icon(Icons.arrow_forward_ios_rounded, size: 20.sp, color: AppColors.notSelected),
          ],
        ),
      ),
    );
  }
}
