import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gap/gap.dart';
import 'package:linkup/presentation/components/signup_page/button_builder.dart';
import 'package:linkup/presentation/components/signup_page/page_title_builder_component.dart';
import 'package:linkup/presentation/screens/loading_screen_post_login_page.dart';
import 'package:linkup/presentation/screens/login_signup_modal_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  void showLoginPopup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.9, 
          child: LoginSignupPage(),
        ), 
      ),
    ).then(
      (value) async {
        if (value is bool) {
          if (value) {
            await Future.delayed(const Duration(milliseconds: 500));

            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const LoadingScreenPostLogin(),
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/landing_page_image.jpg',
              width: 400.w,
              height: 400.h,
              fit: BoxFit.cover,
            ),
          ),
      
          Padding(
            padding: EdgeInsets.only(top: 50.h, left: 20.w, right: 20.w, bottom: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              
              children: [
                Text(
                  'linkup',
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
            
                Gap(5.h),
            
                PageTitle(
                  inputText: "More than just classmates",
                  highlightWord: "classmates",
                  fontSize: 23,
                  textColor: Colors.white,
                ),
            
                Spacer(),
            
                Text(
                  'linkup with your crowd',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
            
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
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.7), // Adjust opacity here (0.0 to 1.0)
                    ),
                  ),
                )
            
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