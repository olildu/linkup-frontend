// ignore_for_file: non_constant_identifier_names

import 'dart:io';

final bool prod = true;

String getBASEURL() {
  if (prod) {
    return 'linkup.olildu.dpdns.org/api/v1';
  }
  if (Platform.isAndroid) {
    return '192.168.123.32:8002/api/v1';
  } else {
    return 'localhost:8002/api/v1';
  }
}

// Upgrade to https or wss when on prod
final String BASE_URL = 'http${prod ? "s" : ""}://${getBASEURL()}';
final String WS_BASE_URL = 'ws${prod ? "s" : ""}://${getBASEURL()}/ws';
