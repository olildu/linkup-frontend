import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linkup/presentation/constants/colors.dart';

class PageTitle extends StatelessWidget {
  final String inputText;
  final dynamic highlightWord;
  final String? subText;
  final double fontSize;
  final Color? textColor;

  const PageTitle({
    super.key,
    required this.inputText,
    required this.highlightWord,  
    this.subText,
    this.fontSize = 31,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: fontSize.sp,
              fontWeight: FontWeight.bold,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            children: _buildTextSpans(inputText, highlightWord, context),
          ),
        ),
    
        Gap(20.h),
    
        if (subText != null)
          Text(
            subText!,
            style: GoogleFonts.poppins(
              fontSize: (fontSize/2).sp,
              fontWeight: FontWeight.w500,
              color: Color.fromARGB(255, 123, 123, 123)
            ),
          ),
    
        Gap(20.h),
        
      ],
    );
  }

  List<TextSpan> _buildTextSpans(String text, dynamic highlightWord, BuildContext context) {
    List<String> highlightWords = highlightWord is List
        ? highlightWord.map((e) => e.toString().toLowerCase()).toList()
        : [highlightWord.toString().toLowerCase()];

    List<TextSpan> spans = [];

    // Split the text by lines
    List<String> lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      RegExp regExp = RegExp(r"[\w'-]+|[^\w\s]");
      Iterable<Match> matches = regExp.allMatches(line);

      for (var match in matches) {
        String part = match.group(0)!;
        bool isHighlighted = highlightWords.any((word) => part.toLowerCase() == word);

        spans.add(TextSpan(
          text: '$part ',
          style: TextStyle(
            color: isHighlighted ? AppColors.primary : textColor ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.normal,
          ),
        ));
      }

      if (i < lines.length - 1) {
        // Add line break
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }


}
