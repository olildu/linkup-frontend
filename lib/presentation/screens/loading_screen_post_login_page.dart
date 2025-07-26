import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linkup/data/get_it/get_it_registerer.dart';
import 'package:linkup/data/token/token_services.dart';
import 'package:linkup/logic/bloc/post_login/post_login_bloc.dart';
import 'package:linkup/logic/bloc/signup/signup_bloc.dart';
import 'package:linkup/presentation/screens/landing_page.dart';
import 'package:linkup/presentation/screens/match_making_page.dart';
import 'package:linkup/presentation/screens/singup_flow_page.dart';

import 'package:linkup/presentation/utils/logo_design.dart';
import 'package:linkup/presentation/utils/navigate_fade_transistion.dart';

class LoadingScreenPostLogin extends StatefulWidget {
  const LoadingScreenPostLogin({super.key});

  @override
  State<LoadingScreenPostLogin> createState() => _LoadingScreenPostLoginState();
}

class _LoadingScreenPostLoginState extends State<LoadingScreenPostLogin> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool animationCompleted = false;
  bool loadingComplete = false;
  bool tokenCheckDone = false;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    TokenServices().tokenExists().then((exists) async {
      loggedIn = exists;
      tokenCheckDone = true;
      if (loggedIn) {
        await TokenServices().registerUserIdIfExists();
        context.read<PostLoginBloc>().add(StartPostLoginEvent());
      }
      _tryNavigate();
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationCompleted = true;
        _tryNavigate();
      }
    });
  }

  void _tryNavigate() {
    if (!tokenCheckDone) return;
    final postLoginState = context.read<PostLoginBloc>().state;

    if (loggedIn && postLoginState is PostLoginLoaded) {
      final goToSignUpPage = postLoginState.goToSignUpPage;

      if (goToSignUpPage) {
        if (animationCompleted && loadingComplete) {
          navigateWithFade(context, BlocProvider(create: (context) => SignupBloc(), child: const SingupFlowPage(initialIndex: -1)));
        }
      } else {
        if (animationCompleted && loadingComplete) {
          navigateWithFade(context, const MatchMakingPage());
        }
      }
    } else {
      if (animationCompleted) {
        navigateWithFade(context, const LandingPage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width * 0.5;
    bool isDarkMode = Theme.of(context).brightness != Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.white : Colors.black,
      body: BlocListener<PostLoginBloc, PostLoginState>(
        listener: (context, state) {
          if (state is PostLoginError || state is PostLoginLoaded) {
            loadingComplete = true;
            _tryNavigate();
          }
        },
        child: Center(
          child: SizedBox(
            width: size,
            height: size,
            child: FadeTransition(
              opacity: _animation,
              child: CustomPaint(size: Size(size, size), painter: DrawingPainter(_animation, isDarkMode ? Colors.black : Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
