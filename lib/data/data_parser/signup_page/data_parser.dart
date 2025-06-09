import 'dart:developer';

class SignUpDataParser {
  static Map data = {};

  static void addData(String key, dynamic value) {
    data[key] = value;

    log(data.toString(), name: "SignUpDataParser");
  } 

  static void printFormattedData() {
    final formattedData = data.entries.map((entry) {
      return '"${entry.key}": ${entry.value}';
    }).join(',\n  ');

    final paddedJson = '{\n  $formattedData\n}';
    log(paddedJson, name: "SignUpDataParser");
  }
}