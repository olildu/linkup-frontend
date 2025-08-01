import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:linkup/data/http_services/city_lookup_http_services/city_lookup_http_services.dart';
import 'package:linkup/presentation/components/signup_page/option_builder.dart';
import 'package:linkup/presentation/components/signup_page/text_input_builder_component.dart';
import 'package:linkup/presentation/utils/debouncer_class.dart';

class CityLookup extends StatefulWidget {
  final Function(String) onChanged;
  const CityLookup({super.key, required this.onChanged});

  @override
  State<CityLookup> createState() => _CityLookupState();
}

class _CityLookupState extends State<CityLookup> {
  final _debouncer = Debouncer(milliseconds: 400);
  final TextEditingController _controller = TextEditingController();
  List<String> _searchResults = _initialCities;

  static const List<String> _initialCities = [
    "Mumbai, Maharashtra",
    "Delhi, Delhi",
    "Bengaluru, Karnataka",
    "Jaipur, Rajasthan",
    "Agra, Uttar Pradesh",
    "Varanasi, Uttar Pradesh",
    "Kolkata, West Bengal",
    "Udaipur, Rajasthan",
    "Chennai, Tamil Nadu",
    "Hyderabad, Telangana",
    "Amritsar, Punjab",
    "Goa, Goa",
    "Kochi, Kerala",
    "Srinagar, Jammu and Kashmir",
    "Darjeeling, West Bengal",
    "Shimla, Himachal Pradesh",
    "Mysuru, Karnataka",
    "Puducherry, Puducherry",
    "Leh, Ladakh",
    "Manali, Himachal Pradesh",
    "Ahmedabad, Gujarat",
  ];

  void _onSearchChanged(String val) {
    if (val.trim().isEmpty) {
      setState(() => _searchResults = _initialCities);
    } else {
      _debouncer.run(() async {
        try {
          final cities = await CityLookupHttpServices.searchCities(val);
          if (mounted) setState(() => _searchResults = cities);
        } catch (_) {
          setState(() => _searchResults = []);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final inputHeight = 80.h;
        final gapHeight = 30.h;

        final remainingHeight = c.maxHeight - inputHeight - gapHeight;

        return Column(
          children: [
            TextInput(label: "City", placeHolder: "Search your hometown", controller: _controller, onChanged: _onSearchChanged),
            Gap(gapHeight),
            SizedBox(
              height: remainingHeight,
              child: SingleChildScrollView(
                child: OptionBuilder(
                  options: _searchResults,
                  textSize: 13,
                  onChanged: (val) {
                    _controller.text = val;
                    widget.onChanged(val);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
