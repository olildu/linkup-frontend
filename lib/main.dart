
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:linkup/logic/bloc/connections/connections_bloc.dart';
import 'package:linkup/logic/bloc/matches/matches_bloc.dart';
import 'package:linkup/logic/bloc/post_login/post_login_bloc.dart';
import 'package:linkup/logic/bloc/profile/own/profile_bloc.dart';
import 'package:linkup/logic/bloc/web_socket/chat_sockets/chat_sockets_bloc.dart';
import 'package:linkup/logic/bloc/web_socket/web_socket_bloc.dart';
import 'package:linkup/presentation/constants/colors.dart';
import 'package:linkup/presentation/screens/loading_screen_post_login_page.dart';
import 'package:linkup/logic/provider/data_validator_provider.dart';
import 'package:linkup/logic/provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataValidatorProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => MatchesBloc()),
          BlocProvider(create: (_) => ConnectionsBloc()),
          BlocProvider(create: (_) => ProfileBloc()),
          BlocProvider(create: (_) => WebSocketBloc()),
          BlocProvider(create: (_) => ChatSocketsBloc()),
          
          BlocProvider(create: (context) => PostLoginBloc(
            matchesBloc: context.read<MatchesBloc>(),
            webSocketBloc: context.read<WebSocketBloc>(), 
            chatSocketsBloc: context.read<ChatSocketsBloc>(),
            profileBloc: context.read<ProfileBloc>(),
            connectionsBloc: context.read<ConnectionsBloc>()
          )),
        ],
        child: const MyApp()
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ScreenUtilInit(
      designSize: const Size(411.43, 866.28),
      child: MaterialApp(
        title: 'linkup',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme, 
        darkTheme: AppTheme.darkTheme, 
        // themeMode: themeProvider.themeMode, 
        themeMode: ThemeMode.dark, 
        home: const LoadingScreenPostLogin(),
        // home: const SingupFlowPage(),
      ),
    );
  }
}
