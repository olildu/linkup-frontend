import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/logic/cubit/theme/theme_cubit.dart';
import 'package:linkup/presentation/constants/colors.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Scaffold(
          appBar: AppBar(
            scrolledUnderElevation: 0,
            title: Text('Settings', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSubtitle('Appearance', 'Customize your theme settings'),
                    Gap(20.h),

                    _buildOption(
                      icon: Icons.dark_mode_rounded,
                      title: themeMode == ThemeMode.dark ? 'Disable Dark Mode' : 'Enable Dark Mode',
                      onTap: (bool value) {
                        context.read<ThemeCubit>().toggleTheme();
                      },
                      value: themeMode == ThemeMode.dark,
                    ),

                    _buildOption(icon: Icons.visibility_off_rounded, title: 'Hide Online Status', onTap: (bool value) {}, value: false),

                    _buildOption(icon: Icons.visibility_off_rounded, title: 'Hide Online Status', onTap: (bool value) {}, value: false),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption({required IconData icon, required String title, required Function(bool) onTap, required bool value}) {
    return Container(
      margin: EdgeInsets.only(bottom: 30.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: Theme.of(context).colorScheme.onSurface),
          Gap(10.w),
          Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          const Spacer(),
          CupertinoSwitch(value: value, onChanged: onTap),
        ],
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
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.notSelected : const Color.fromARGB(255, 141, 141, 141),
          ),
        ),
      ],
    );
  }
}
