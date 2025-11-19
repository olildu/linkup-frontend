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

  late PostLoginBloc _postLoginBloc;
  final TokenServices _tokenServices = TokenServices();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _postLoginBloc = context.read<PostLoginBloc>();
    initializer();
  }

  Future<void> initializer() async {
    await _tokenCheck();
  }

  Future<void> _tokenCheck() async {
    bool exists = await _tokenServices.tokenExists();

    if (exists) {
      await _tokenServices.registerUserIdIfExists();
      _postLoginBloc.add(StartPostLoginEvent());
    } else {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          navigateWithFade(context, LandingPage(), allowBack: false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width * 0.5;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: BlocListener<PostLoginBloc, PostLoginState>(
        listener: (context, state) {
          if (state is PostLoginLoaded) {
            if (state.goToSignUpPage) {
              navigateWithFade(context, BlocProvider(create: (context) => SignupBloc(), child: SingupFlowPage(initialIndex: -1)), allowBack: false);
            } else {
              navigateWithFade(context, MatchMakingPage(), allowBack: false);
            }
          } else if (state is PostLoginError) {
            navigateWithFade(context, LandingPage(), allowBack: false);
          }
        },
        child: Center(
          child: SizedBox(
            width: size,
            height: size,
            child: FadeTransition(opacity: _animation, child: CustomPaint(size: Size(size, size), painter: DrawingPainter(_animation, isDarkMode ? Colors.white : Colors.black))),
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
