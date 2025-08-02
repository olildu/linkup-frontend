import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/presentation/components/login/text_input_field.dart';
import 'package:linkup/presentation/components/signup_page/button_builder.dart';
import 'package:linkup/data/http_services/auth_http_services/auth_http_services.dart';
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

    _emailController.value = const TextEditingValue(text: 'ebinsanthosh06@gmail.com');
    _passwordController.value = const TextEditingValue(text: 'OOMBmyrefc!12');

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
                  onPressed: () {},
                  child: Text('Forgot Password ?', style: TextStyle(fontSize: 14.sp, color: Colors.blue, fontWeight: FontWeight.w500)),
                ),
              ],
            ),

            ButtonBuilder(
              width: double.infinity,
              height: 55.h,
              text: 'Log In',
              onPressed: _loginLogic,
              isEnabled: _isFormValid,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
