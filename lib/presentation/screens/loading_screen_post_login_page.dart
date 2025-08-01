import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  final String _logTag = 'LoadingScreen';

  bool _animationCompleted = false;
  bool _userLoggedIn = false;

  late PostLoginBloc _postLoginBloc;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _postLoginBloc = context.read<PostLoginBloc>();

    _tokenCheck();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationCompleted = true;
        _navigateLogic();
      }
    });
  }

  void _tokenCheck() {
    TokenServices().tokenExists().then((exists) {
      _userLoggedIn = exists;
      if (exists) {
        _postLoginBloc.add(StartPostLoginEvent());
      }
    });
  }

  void _navigateLogic() {
    final state = _postLoginBloc.state;
    if (!_animationCompleted && state is! PostLoginLoaded) return;

    if (_userLoggedIn && state is PostLoginLoaded) {
      if (state.goToSignUpPage) {
        navigateWithFade(context, BlocProvider(create: (context) => SignupBloc(), child: SingupFlowPage(initialIndex: -1)));
      } else {
        navigateWithFade(context, MatchMakingPage());
      }
    } else {
      navigateWithFade(context, LandingPage());
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
          if (state is PostLoginError || state is PostLoginLoaded) {}
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
