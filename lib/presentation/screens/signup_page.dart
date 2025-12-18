import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/data/enums/otp_subject_enum.dart';
import 'package:linkup/logic/bloc/otp/otp_bloc.dart';
import 'package:linkup/presentation/components/login/otp_input_field.dart';
import 'package:linkup/presentation/components/login/text_input_field.dart';
import 'package:linkup/presentation/components/signup_page/button_builder.dart';

class SignUpPage extends StatefulWidget {
  final Function(int) tabHeightChange;
  const SignUpPage({super.key, required this.tabHeightChange});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final bool _hasError = false;
  bool _isEmailValid = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  late final OtpBloc _otpBloc;

  void _validateEmail() {
    final email = _emailController.text.trim();
    final isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    setState(() {
      _isEmailValid = isEmailValid;
    });
  }

  void _validateOTP() {
    final email = _emailController.text.trim();
    final isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    setState(() {
      _isEmailValid = isEmailValid;
    });
  }

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      _emailController.text = 'ebinsanthosh06@gmail.com';
      _passwordController.text = 'OOMBmyrefc!12';
      _confirmPasswordController.text = 'OOMBmyrefc!12';
      _otpController.text = '123456';
    }

    _validateEmail();

    _emailController.addListener(_validateEmail);
    _otpController.addListener(_validateOTP);
    _otpBloc = context.read<OtpBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFAFAFAFA),
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: BlocConsumer<OtpBloc, OtpBlocState>(
            listener: (context, state) {
              if (state is OTPPasswordCreated) {
                Navigator.pop(context, true);
              }
              if (state is OTPVerified) {
                widget.tabHeightChange(0);
              }
            },
            builder: (context, state) {
              if (state is OtpBlocInitial || state is OtpSentLoading) {
                return _emailEntry(key: const ValueKey('emailView'), state: state);
              } else if (state is OtpSent || state is OTPVerificationLoading) {
                return _otpVerification(key: const ValueKey('otpView'), state: state);
              } else if (state is OTPVerified || state is OTPPasswordLoading || state is OTPPasswordCreated) {
                return _passwordEntry(key: const ValueKey('passwordView'), state: state);
              } else {
                return _emailEntry(key: const ValueKey('emailView'), state: state);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _emailEntry({required ValueKey key, required OtpBlocState state}) {
    return Column(
      key: key,
      children: [
        TextInputField(label: 'Email', hintText: 'Enter your MUJ college email', controller: _emailController, hasError: _hasError),
        if (_hasError)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0.h, horizontal: 5.w),
            child: Text(
              'Please enter a valid MUJ email address (ending with @muj.manipal.edu).',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          ),

        Spacer(),
        ButtonBuilder(
          width: double.infinity,
          height: 55.h,
          text: 'Verify with OTP',
          onPressed: () {
            _otpBloc.add(SendOTPEvent(email: _emailController.text.trim()));
          },
          isLoading: state is OtpSentLoading,
          isEnabled: _isEmailValid,
        ),
      ],
    );
  }

  Widget _otpVerification({required ValueKey key, required OtpBlocState state}) {
    return Column(
      key: key,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OtpInputField(label: 'OTP', hintText: 'Enter the OTP', controller: _otpController, hasError: _hasError),
        if (_hasError)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0.h, horizontal: 5.w),
            child: Text(
              'Please recheck your OTP code.',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          ),

        Spacer(),

        ButtonBuilder(
          width: double.infinity,
          height: 55.h,
          text: 'Submit OTP',
          onPressed: () {
            _otpBloc.add(VerifyOTPEvent(otp: int.parse(_otpController.text.trim()), email: _emailController.text.trim(), subject: EmailOTPSubject.emailVerification));
          },
          isLoading: state is OTPVerificationLoading,
          isEnabled: _otpController.text.trim().length == 6,
        ),
      ],
    );
  }

  Widget _passwordEntry({required ValueKey key, required OtpBlocState state}) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        key: key,
        children: [
          TextInputField(label: 'Password', hintText: 'Enter your new password', obscureText: true, controller: _passwordController, hasError: _hasError),

          Gap(10.h),

          TextInputField(label: 'Confirm Password', hintText: 'Re-enter your new password', controller: _confirmPasswordController, hasError: _hasError, obscureText: true),
          if (_hasError)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0.h, horizontal: 5.w),
              child: Text(
                'Please enter a valid password.',
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
              ),
            ),

          Gap(60.h),

          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ButtonBuilder(
                width: double.infinity,
                height: 55.h,
                text: 'Save password',
                onPressed: () {
                  _otpBloc.add(CompleteSignUpEvent(password: _passwordController.text.trim()));
                },
                isLoading: state is OTPPasswordLoading,
                isEnabled: _isEmailValid,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
