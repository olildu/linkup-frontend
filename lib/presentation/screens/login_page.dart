import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/logic/bloc/otp/otp_bloc.dart';
import 'package:linkup/presentation/components/login/text_input_field.dart';
import 'package:linkup/presentation/components/signup_page/button_builder.dart';
import 'package:linkup/data/http_services/auth_http_services/auth_http_services.dart';
import 'package:linkup/presentation/screens/forgot_password_modal_page.dart';
import 'package:linkup/presentation/screens/loading_screen_post_login_page.dart';
import 'package:linkup/presentation/utils/show_error_toast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isFormValid = false;
  bool _isLoading = false;
  bool _hasError = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void validateEmailPassword() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    final isPasswordValid = password.length >= 7;

    setState(() {
      _isFormValid = isEmailValid && isPasswordValid;
    });
  }

  void _showForgotPopup() {
    double modalHeight = 0.35;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void onTabChange(String value) {
              double newHeight;

              switch (value) {
                case "email-entry":
                  newHeight = 0.35;
                  break;
                case "otp-entry":
                  newHeight = 0.35;
                  break;
                case "password-entry":
                  newHeight = 0.5;
                  break;

                default:
                  newHeight = 0.35;
              }

              setModalState(() {
                modalHeight = newHeight;
              });
            }

            return ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: (MediaQuery.of(context).size.height * modalHeight) + MediaQuery.of(context).viewInsets.bottom,
                child: BlocProvider(
                  create: (context) => OtpBloc(),
                  child: ForgotPasswordModalPage(
                    tabHeightChange: (String value) {
                      onTabChange(value);
                    },
                    filledEmail: _emailController.text,
                  ),
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

  void _handleResponse(int result) {
    switch (result) {
      case 200:
        Navigator.of(context).pop(true);
        break;
      case 400:
        setState(() {
          _hasError = true;
        });

        showToast(context: context, message: 'Invalid email or password');

        break;
      default:
        setState(() {
          _hasError = true;
        });
    }
  }

  void _loginLogic() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      int result = await AuthHttpServices.login(_emailController.text.trim(), _passwordController.text);
      _handleResponse(result);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      _emailController.value = const TextEditingValue(text: 'ebinsanthosh06@gmail.com');
      _passwordController.value = const TextEditingValue(text: 'OOMBmyrefc!12');
    }

    validateEmailPassword();

    _emailController.addListener(validateEmailPassword);
    _passwordController.addListener(validateEmailPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFafafafa),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextInputField(label: 'Email', hintText: 'Enter your email', controller: _emailController, hasError: _hasError),

            Gap(24.h),

            TextInputField(
              label: 'Password',
              hintText: '••••••••',
              controller: _passwordController,
              obscureText: _obscurePassword,
              hasError: _hasError,
              toggleObscure: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),

            Gap(16.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // Open another modal which will overlap the outer login and signup
                    _showForgotPopup();
                  },
                  child: Text(
                    'Forgot Password ?',
                    style: TextStyle(fontSize: 14.sp, color: Colors.blue, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            ButtonBuilder(width: double.infinity, height: 55.h, text: 'Log In', onPressed: _loginLogic, isEnabled: _isFormValid, isLoading: _isLoading),
          ],
        ),
      ),
    );
  }
}
