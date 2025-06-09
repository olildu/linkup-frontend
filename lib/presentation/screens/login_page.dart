import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/presentation/components/signup_page/button_builder.dart';
import 'package:linkup/data/http_services/auth_http_services/auth_http_services.dart';
import 'package:linkup/presentation/utils/scaffold_message_display.dart';

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

  void _handleResponse(int result) {
    switch (result) {
      case 200:
        Navigator.of(context).pop(true);
        break;
      case 400:
        setState(() {
          _hasError = true;
        });

        showScaffoldMessage(
          context: context,
          message: 'Invalid email or password',
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );

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
      int result = await AuthHttpServices.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      _handleResponse(result);
    }
    finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _emailController.value = const TextEditingValue(text: 'user@example.com');
    _passwordController.value = const TextEditingValue(text: 'StrongP@sswOrd123!');

    validateEmailPassword();

    _emailController.addListener(validateEmailPassword);
    _passwordController.addListener(validateEmailPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFafafafa),
      body : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textField(
              label: 'Email',
              hintText: 'Enter your email',
              controller: _emailController,
              hasError: _hasError,
            ),

            Gap(24.h),

            _textField(
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
                  onPressed: () {},
                  child: Text(
                    'Forgot Password ?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            Gap(24.h),

            ButtonBuilder(
              width: double.infinity,
              height: 60.h,
              text: 'Log In',
              onPressed: _loginLogic,
              isEnabled: _isFormValid,
              isLoading: _isLoading,
            ),
          ],
        ),
      )
    );
  }

  Widget _textField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    bool hasError = false,
  }) {
    final borderColor = hasError ? const Color.fromARGB(255, 244, 21, 5) : Colors.grey[300]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Gap(8.h),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.blue),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            suffixIcon: toggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: toggleObscure,
                  )
                : null,
          ),
        ),
      ],
    );
  }


}