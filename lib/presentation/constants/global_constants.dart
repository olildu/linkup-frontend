// ignore_for_file: non_constant_identifier_names

import 'dart:io';

final bool prod = false;

String getBASEURL() {
  if (prod) {
    return 'linkup-backend.olildu.dpdns.org';
  }
  if (Platform.isAndroid) {
    return '10.0.2.2:8002';
  } else {
    return 'localhost:8002';
  }
}

// Upgrade to https or wss when on prod
final String BASE_URL = 'http${prod ? "s" : ""}://${getBASEURL()}';
final String WS_BASE_URL = 'ws${prod ? "s" : ""}://${getBASEURL()}/ws';
