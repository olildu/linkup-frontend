// lib/presentation/screens/forgot_password_modal_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/logic/bloc/otp/otp_bloc.dart';
import 'package:linkup/presentation/components/login/text_input_field.dart';
import 'package:linkup/presentation/components/login/otp_input_field.dart';
import 'package:linkup/presentation/components/signup_page/button_builder.dart';
import 'package:linkup/presentation/constants/colors.dart';

class ForgotPasswordModalPage extends StatefulWidget {
  final Function(String) tabHeightChange;

  const ForgotPasswordModalPage({super.key, required this.tabHeightChange});

  @override
  State<ForgotPasswordModalPage> createState() => _ForgotPasswordModalPageState();
}

class _ForgotPasswordModalPageState extends State<ForgotPasswordModalPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late OtpBloc _otpBloc;

  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Assuming OtpBloc is provided by the parent widget (LoginPage's _showForgotPopup)
    _otpBloc = context.read<OtpBloc>();

    _emailController.addListener(_validateFields);
    _passwordController.addListener(_validateFields);
    _confirmPasswordController.addListener(_validateFields);
    _otpController.addListener(_validateFields);

    _validateFields();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateFields() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Simple email validation
    final isEmailValidNow = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    // Simple password validation: at least 7 characters
    final isPasswordValidNow = password.length >= 7;
    // Confirm password validation
    final isConfirmPasswordValidNow = isPasswordValidNow && (password == confirmPassword);

    if (mounted) {
      setState(() {
        _isEmailValid = isEmailValidNow;
        _isPasswordValid = isPasswordValidNow;
        _isConfirmPasswordValid = isConfirmPasswordValidNow;
      });
    }
  }

  void _onEmailSubmitted() {
    if (_isEmailValid) {
      _otpBloc.add(SendOTPEvent(email: _emailController.text.trim()));
      setState(() => _hasError = false);
    }
  }

  void _onOTPSubmitted() {
    if (_otpController.text.trim().length == 6) {
      // Note: The logic in AuthHttpServices::verifyEmailOTP seems to be for signup and provides an email_hash.
      // This is being reused here for password reset verification.
      _otpBloc.add(VerifyOTPEvent(otp: int.parse(_otpController.text.trim()), email: _emailController.text.trim()));
      setState(() => _hasError = false);
    }
  }

  void _onPasswordSubmitted() {
    if (_isPasswordValid && _isConfirmPasswordValid) {
      // Note: SendPasswordEvent uses the emailHash from successful OTP verification (in OtpBloc) to complete the signup,
      // which should be adapted for a password *reset* endpoint in a production app, but for now, we reuse the existing flow
      // which assumes completion of credentials. The expected result is a success pop.
      _otpBloc.add(SendPasswordEvent(password: _passwordController.text.trim()));
      setState(() => _hasError = false);
    }
  }

  void _safeTabHeightChange(String tab) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.tabHeightChange(tab);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Gap(10.h),

              // Header with Back Button and Title
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(24.r),
                    splashColor: AppColors.lightText.withOpacity(0.25),
                    highlightColor: AppColors.lightText.withOpacity(0.1),
                    child: Padding(
                      padding: EdgeInsets.all(8.r),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp, color: AppColors.lightText),
                    ),
                  ),
                  Gap(10.w),
                  Text(
                    "Forgot Password?",
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w400, color: AppColors.lightText),
                  ),
                ],
              ),

              Gap(30.h),

              // Dynamic content based on OtpBlocState
              Expanded(
                child: BlocConsumer<OtpBloc, OtpBlocState>(
                  listener: (context, state) {
                    if (state is OtpSentFailed || state is OTPVerificationFailed || state is OTPPasswordFailed) {
                      setState(() => _hasError = true);
                    } else if (state is OTPPasswordCreated) {
                      Navigator.pop(context, true);
                    }

                    if (state is OtpBlocInitial || state is OtpSentLoading || state is OtpSentFailed) {
                      _safeTabHeightChange("email-entry");
                    } else if (state is OtpSent || state is OTPVerificationLoading || state is OTPVerificationFailed) {
                      _safeTabHeightChange("otp-entry");
                    } else if (state is OTPVerified || state is OTPPasswordLoading || state is OTPPasswordCreated || state is OTPPasswordFailed) {
                      _safeTabHeightChange("password-entry");
                    }
                  },
                  builder: (context, state) {
                    if (state is OtpBlocInitial || state is OtpSentLoading || state is OtpSentFailed) {
                      return _buildEmailEntry(state);
                    } else if (state is OtpSent || state is OTPVerificationLoading || state is OTPVerificationFailed) {
                      return _buildOtpVerification(state);
                    } else {
                      return _buildPasswordEntry(state);
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

  Widget _buildEmailEntry(OtpBlocState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextInputField(label: 'Email', hintText: 'Enter your registered email', controller: _emailController, hasError: _hasError || state is OtpSentFailed),
        if (_hasError || state is OtpSentFailed)
          Padding(
            padding: EdgeInsets.only(top: 8.0.h, left: 5.w),
            child: Text(
              'Invalid email or failed to send OTP. Please check your email and try again.',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          ),
        Spacer(),
        ButtonBuilder(width: double.infinity, height: 55.h, text: 'Send OTP', onPressed: _onEmailSubmitted, isLoading: state is OtpSentLoading, isEnabled: _isEmailValid),
      ],
    );
  }

  Widget _buildOtpVerification(OtpBlocState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OtpInputField(label: 'OTP Code', hintText: '••••••', controller: _otpController, hasError: _hasError || state is OTPVerificationFailed),
        if (_hasError || state is OTPVerificationFailed)
          Padding(
            padding: EdgeInsets.only(top: 8.0.h, left: 5.w),
            child: Text(
              'Invalid OTP. Please check your code and try again.',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          ),
        Spacer(),
        ButtonBuilder(
          width: double.infinity,
          height: 55.h,
          text: 'Verify OTP',
          onPressed: _onOTPSubmitted,
          isLoading: state is OTPVerificationLoading,
          isEnabled: _otpController.text.trim().length == 6,
        ),
      ],
    );
  }

  Widget _buildPasswordEntry(OtpBlocState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        TextInputField(
          label: 'New Password',
          hintText: 'Enter your new password',
          obscureText: true,
          controller: _passwordController,
          hasError: _hasError || state is OTPPasswordFailed,
          toggleObscure: () {}, // Placeholder for toggle visibility logic if needed
        ),
        Gap(24.h),
        TextInputField(
          label: 'Confirm New Password',
          hintText: 'Re-enter your new password',
          obscureText: true,
          controller: _confirmPasswordController,
          hasError: _hasError || state is OTPPasswordFailed,
          toggleObscure: () {},
        ),
        if ((_hasError || state is OTPPasswordFailed) && (_passwordController.text.isNotEmpty || _confirmPasswordController.text.isNotEmpty))
          Padding(
            padding: EdgeInsets.only(top: 8.0.h, left: 5.w),
            child: Text(
              'Passwords do not match or are too short (min 7 characters).',
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
            ),
          ),
        Spacer(),
        ButtonBuilder(
          width: double.infinity,
          height: 55.h,
          text: 'Change Password',
          onPressed: _onPasswordSubmitted,
          isLoading: state is OTPPasswordLoading,
          isEnabled: _isPasswordValid && _isConfirmPasswordValid,
        ),
      ],
    );
  }
}
