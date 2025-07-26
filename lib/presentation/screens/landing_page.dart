import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/presentation/components/signup_page/button_builder.dart';
import 'package:linkup/presentation/components/signup_page/page_title_builder_component.dart';
import 'package:linkup/presentation/screens/loading_screen_post_login_page.dart';
import 'package:linkup/presentation/screens/login_signup_modal_page.dart';
import 'package:linkup/presentation/screens/singup_flow_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  void showLoginPopup() {
    double modalHeight = 0.55;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: MediaQuery.of(context).size.height * modalHeight,
                child: LoginSignupPage(
                  onTabChange: (int tabIndex) {
                    double newHeight;

                    switch (tabIndex) {
                      case 0:
                        newHeight = 0.55;
                        break;
                      case 1:
                        newHeight = 0.37;
                        break;
                      default:
                        newHeight = 0.5;
                    }

                    setModalState(() {
                      modalHeight = newHeight;
                    });
                  },
                ),
              ),
            );
          },
        );
      },
    ).then((value) async {
      if (value is bool && value) {
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const LoadingScreenPostLogin()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/landing_page_image.jpg', width: 400.w, height: 400.h, fit: BoxFit.cover)),

          Padding(
            padding: EdgeInsets.only(top: 50.h, left: 20.w, right: 20.w, bottom: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text('linkup', style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold, color: Colors.white)),

                Gap(5.h),

                PageTitle(inputText: "More than just classmates", highlightWord: "classmates", fontSize: 23, textColor: Colors.white),

                Spacer(),

                Text('linkup with your crowd', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500, color: Colors.white)),

                Gap(20.h),

                ButtonBuilder(
                  text: "Continue with MUJ ID",
                  onPressed: () {
                    showLoginPopup();
                  },
                  height: 60.h,
                ),

                Gap(20.h),

                Center(
                  child: Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy.',
                    style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}
