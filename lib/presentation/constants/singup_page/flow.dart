import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/presentation/components/common/bullet_point_builder.dart';
import 'package:linkup/presentation/components/common/image_picker_builder.dart';
import 'package:linkup/presentation/components/signup_page/image_builder.dart';
import 'package:linkup/presentation/components/signup_page/option_builder.dart';
import 'package:linkup/presentation/components/signup_page/picker_builder_component.dart';
import 'package:linkup/presentation/constants/singup_page/date_picker.dart';
import 'package:linkup/presentation/components/signup_page/page_title_builder_component.dart';
import 'package:linkup/presentation/components/signup_page/text_input_builder_component.dart';
import 'package:linkup/logic/provider/data_validator_provider.dart';
import 'package:linkup/logic/provider/theme_provider.dart';
import 'package:linkup/data/data_parser/signup_page/data_parser.dart';
import 'package:provider/provider.dart';

class SignUpPageFlow {
  final BuildContext context;
  late final List<Map<String, dynamic>> flow;
  final Map<String, dynamic>? initialData;

  // Constructor
   SignUpPageFlow(this.context, { this.initialData }) {
    _initializeFlow();
  }

  // Access dataValidatorProvider
  DataValidatorProvider get dataValidatorProvider => Provider.of<DataValidatorProvider>(context, listen: false);
  ThemeProvider get themeProvider => Provider.of<ThemeProvider>(context, listen: false);

  // Define flow steps
  void _initializeFlow() {
    print("Initializing SignUpPageFlow with initialData: $initialData");
    flow = [
      // Intro slide  
      {
        'title': PageTitle(
          inputText: "Tell us who you are, So we know whom to link you up with later",
          highlightWord: "who",
          subText: "linkup keeps your personal information safe and private",
        ),
        'action': ImageBuilder(
          imagePath: "assets/images/care.png",
          darkMode: themeProvider.isDarkMode,
        ),
        "showProgressBar": false,
      },

      // Name input
      {
        'title': PageTitle(
          inputText: "Your name so others know you!",
          highlightWord: "name",
        ),
        'action': TextInput(
          label: "Name",
          placeHolder: "Enter your name",
          onChanged: (val) {
            if (val.trim().isNotEmpty) {
              dataValidatorProvider.allowDisallow(true);
              SignUpDataParser.addData("name", val.trim());
            } else {
              dataValidatorProvider.allowDisallow(false);
            }
          },
        ),
        'index': 0,
      },

      // Date picker
      {
        'title': PageTitle(
          inputText: "When's your birthday? We'll celebrate with you!",
          highlightWord: "birthday",
        ),
        'action': DatePicker(
          onChanged: (val) {
            Future.delayed(const Duration(milliseconds: 500), () {
              dataValidatorProvider.allowDisallow(true);
              SignUpDataParser.addData("dob", {
                "day": val.day,
                "month": val.month,
                "year": val.year,
              });
            });
          },
        ),
        'index': 1,
      },

      // Gender picker
      {
        'title': PageTitle(
          inputText: "Select your gender to help others get to know you better",
          highlightWord: "gender",
        ),
        'action': OptionBuilder(
          options: ["Male", "Female"],
          onChanged: (val) {
            dataValidatorProvider.allowDisallow(true);
            SignUpDataParser.addData("gender", val);
          },
        ),
        'index': 2,
      },

      // Interest selection
      {
        'title': PageTitle(
          inputText: "Let us know who you're interested in connecting with",
          highlightWord: "interested",
        ),
        'action': OptionBuilder(
          options: ["Male", "Female"],
          onChanged: (val) {
            dataValidatorProvider.allowDisallow(true);
            SignUpDataParser.addData("interested", val);
          },
        ),
        'index': 3,
      },

      // Major picker
      {
        'title': PageTitle(
          inputText: "What's your major? Let's connect you with others in the field!",
          highlightWord: "major",
        ),
        'action': BuildPicker(
          controller: FixedExtentScrollController(initialItem: 0),
          items: [
            "Computer Science",
            "Information Technology",
            "Mechanical Engineering",
            "Civil Engineering",
            "Electrical Engineering"
          ],
          onSelectedItemChanged: (index) {
            Future.delayed(const Duration(milliseconds: 500), () {
              dataValidatorProvider.allowDisallow(true);
              SignUpDataParser.addData("major", [
                "Computer Science",
                "Information Technology",
                "Mechanical Engineering",
                "Civil Engineering",
                "Electrical Engineering"
              ][index]);
            });
          },
          dividerGap: 0.15,
        ),
        'index': 4,
      },

      // Year picker
      {
        'title': PageTitle(
          inputText: "What year are you in? We'll match you with others in your journey",
          highlightWord: "year",
        ),
        'action': BuildPicker(
          controller: FixedExtentScrollController(initialItem: 0),
          items: ["1st Year", "2nd Year", "3rd Year", "4th Year"],
          onSelectedItemChanged: (index) {
            Future.delayed(const Duration(milliseconds: 500), () {
              dataValidatorProvider.allowDisallow(true);
              SignUpDataParser.addData("year", [
                "1st Year",
                "2nd Year",
                "3rd Year",
                "4th Year"
              ][index]);
            });
          },
          dividerGap: 0.15,
        ),
        'index': 5,
      },

      // Image upload
      {
        'title': PageTitle(
          inputText: "Add at least 2 photos so others can see you and put face to name",
          highlightWord: "photos",
        ),
        'action': SingleChildScrollView(
          child: Column(
            children: [
              ImagePickerBuilder(
                onImagesChanged: (p0) {
                  if (p0.isNotEmpty && p0.length >= 2) {
                    dataValidatorProvider.allowDisallow(true);
                    SignUpDataParser.addData("photos", p0);
                  } else {
                    dataValidatorProvider.allowDisallow(false);
                  }
                },
                maxImages: 6,
                allowMultipleSelection: true,
              ),
              Gap(10.h),
              BulletPointBuilder(
                items: [
                  "Upload photos where your face is clearly visible",
                  "Photos that don't resemble you will be removed and flagged",
                ],
              ),
            ],
          ),
        ),

        'index': 6,
      },

      // About input
      {
        'title': PageTitle(
          inputText: "Tell us about yourself. We'd love to know you!",
          highlightWord: "about",
        ),
        'action': TextInput(
          label: "About",
          placeHolder: "",
          onChanged: (val) {
            if (val.isNotEmpty) {
              dataValidatorProvider.allowDisallow(true);
              SignUpDataParser.addData("about", val);
            } else {
              dataValidatorProvider.allowDisallow(false);
            }
          },
        ),
        'index': 7,
      },

      // Transition slide
      {
        'title': PageTitle(
          inputText: "One last step\nTell us what you love, So we can match you better",
          highlightWord: ["love", "match"],
        ),
        'action': ImageBuilder(
          imagePath: "assets/images/like.png",
          darkMode: themeProvider.isDarkMode,
        ),
        'showProgressBar': false,
      },

      // Height picker
      {
        'title': PageTitle(
          inputText: "How tall are you? Some people are into stats!",
          highlightWord: "tall",
        ),
        'action': BuildPicker(
          controller: FixedExtentScrollController(initialItem: 0),
          items: List.generate(100, (index) => "${110 + index + 1} cm"),
          onSelectedItemChanged: (index) {
            Future.delayed(const Duration(milliseconds: 500), () {
              dataValidatorProvider.allowDisallow(true);
              SignUpDataParser.addData(
                "height",
                List.generate(100, (index) => "${110 + index + 1} cm")[index],
              );
            });
          },
          selectedIndex: initialData?["height"] != null ? (initialData!["height"] - 111) : null,
          dividerGap: 0.15,
        ),
        'showProgressBar': false,
      },

      // Weight picker
      {
        'title': PageTitle(
          inputText: "What's your weight? Totally up to you if you want to share.",
          highlightWord: "weight",
        ),
        'action': BuildPicker(
          controller: FixedExtentScrollController(initialItem: 0),
          items: List.generate(90, (index) => "${30 + index + 1} kg"),
          onSelectedItemChanged: (index) {
            Future.delayed(const Duration(milliseconds: 500), () {
              dataValidatorProvider.allowDisallow(true);
              SignUpDataParser.addData(
                "weight",
                List.generate(90, (index) => "${30 + index + 1} kg")[index],
              );
            });
          },
          dividerGap: 0.15,
          selectedIndex: initialData?["weight"] != null ? (initialData!["weight"] - 31) : null,
        ),
        'showProgressBar': false,
      },

      // Religion options
      {
        'title': PageTitle(
          inputText: "What's your religion? Only if you feel like sharing!",
          highlightWord: "religion",
        ),
        'action': OptionBuilder(
          options: [
            "Islam",
            "Sikhism",
            "Jainism",
            "Christianity",
            "Hinduism",
            "Buddhism",
            "Others"
          ],
          onChanged: (val) {
            dataValidatorProvider.allowDisallow(true);
            SignUpDataParser.addData("religion", val);
          },
          currentOption: initialData?['religion'],
        ),
        'showProgressBar': false,
      },

      // Smoking habit
      {
        'title': PageTitle(
          inputText: "Do you smoke? Just helping people vibe better",
          highlightWord: "smoke",
        ),
        'action': OptionBuilder(
          options: [
            "Yes",
            "Trying to quit",
            "Occasionally",
            "No",
            "No, prefer non-smokers"
          ],
          onChanged: (val) {
            dataValidatorProvider.allowDisallow(true);
            SignUpDataParser.addData("smoke", val);
          },
          currentOption: initialData?["smoking_info"],
        ),
        'showProgressBar': false,
      },

      // Drinking habit
      {
        'title': PageTitle(
          inputText: "Do you enjoy a drink now and then or not your thing?",
          highlightWord: "drink",
        ),
        'action': OptionBuilder(
          options: [
            "Yes",
            "Trying to quit",
            "Occasionally",
            "No",
            "No, prefer non-drinkers"
          ],
          onChanged: (val) {
            dataValidatorProvider.allowDisallow(true);
            SignUpDataParser.addData("drink", val);
          },
          currentOption: initialData?["drinking_info"],
        ),
        'showProgressBar': false,
      },

      // Connection type
      {
        'title': PageTitle(
          inputText: "What kind of connection are you looking for?",
          highlightWord: "connection",
        ),
        'action': OptionBuilder(
          options: [
            "Casual",
            "Open to anything",
            "Serious",
            "Friends",
            "Not sure yet"
          ],
          onChanged: (val) {
            dataValidatorProvider.allowDisallow(true);
            SignUpDataParser.addData("connection", val);
          },
          currentOption: initialData?["looking_for"],
        ),
        'showProgressBar': false,
      },
    ];
  }
}
