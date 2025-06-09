import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/presentation/components/signup_page/animation_handlers.dart';
import 'package:linkup/presentation/components/signup_page/progress_bar_component.dart';
import 'package:linkup/presentation/components/signup_page/button_builder.dart';
import 'package:linkup/presentation/constants/colors.dart';
import 'package:linkup/presentation/constants/singup_page/flow.dart';
import 'package:linkup/presentation/screens/match_making_page.dart';
import 'package:linkup/logic/provider/data_validator_provider.dart';
import 'package:linkup/data/data_parser/signup_page/data_parser.dart';
import 'package:provider/provider.dart';

class SingupFlowPage extends StatefulWidget {
  final int initialIndex;
  final dynamic initialData;

  const SingupFlowPage({
    super.key,
    this.initialIndex = 0,
    this.initialData,
  });

  @override
  State<SingupFlowPage> createState() => _SingupFlowPageState();
}

class _SingupFlowPageState extends State<SingupFlowPage> {
  late int _currentIndex;
  int _progressBarIndex = 0;
  late DataValidatorProvider _dataValidatorProvider;
  late bool _isNextButtonEnabled;
  late SignUpPageFlow _signUpPageFlow;

  @override
  void initState() {
    super.initState();
    _signUpPageFlow = SignUpPageFlow(
      context,
      initialData: widget.initialData as Map<String,dynamic>?,
    );
    _dataValidatorProvider = Provider.of<DataValidatorProvider>(context, listen: false);
    _isNextButtonEnabled = _dataValidatorProvider.allowNext;

    _currentIndex = widget.initialIndex;

    _dataValidatorProvider.addListener(() {
      if (mounted) {
        setState(() {
          _isNextButtonEnabled = _dataValidatorProvider.allowNext;
        });
      }
    });

    decideNextButtonState();
  }

  void decideNextButtonState() {
    if (_signUpPageFlow.flow[_currentIndex]["showProgressBar"] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dataValidatorProvider.allowDisallow(true);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dataValidatorProvider.allowDisallow(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _signUpPageFlow.flow[_currentIndex]["showProgressBar"] == null
                ? ProgressBarComponent(
                    currentIndex: _progressBarIndex,
                    totalSteps: 8,
                  )
                : const SizedBox.shrink(),
              
              Gap(20.h),

              Expanded(
                child: PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 400),
                  reverse: false,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SharedAxisTransition(
                      animation: animation,
                      transitionType: SharedAxisTransitionType.horizontal,
                      child: child,
                    );
                  },
                  child: buildFlowPage(_currentIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFlowPage(int index) {
    return KeyedSubtree(
      key: ValueKey(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: FadeTransition(
              opacity: AlwaysStoppedAnimation(1),
              child: _signUpPageFlow.flow[index]["title"],
            ),
          ),
      
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
              );
              },
              child: KeyedSubtree(
                key: ValueKey('action_$index'),
                child: _signUpPageFlow.flow[index]["action"],
              ),
            ),
          ),
      
          Gap(20.h),
          
          ButtonBuilder(
            text: _currentIndex < _signUpPageFlow.flow.length - 1 ? "Next" : "Finish",
            onPressed: () {
              if (!_isNextButtonEnabled) {
                return;
              }
      
              setState(() {
                if (_currentIndex < _signUpPageFlow.flow.length - 1) {
                  _currentIndex++;
                  if (_signUpPageFlow.flow[_currentIndex]["showProgressBar"] == null) {
                    _progressBarIndex = _signUpPageFlow.flow[_currentIndex]["index"];
                  }
                } else{
                  SignUpDataParser.printFormattedData();
                  if (widget.initialIndex > 0) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const MatchMakingPage(),
                      ),
                    );
                  }
                }
                decideNextButtonState();
              });
      
              decideNextButtonState();
            },
            backgroundColor: _isNextButtonEnabled ? AppColors.primary : AppColors.notSelected,
            textColor: Colors.white,
            isFullWidth: true,
            height: 65.h,
            borderRadius: 15.r,
          )
        ],
      ),
    );
  }
}
