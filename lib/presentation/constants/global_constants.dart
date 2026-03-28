// ignore_for_file: non_constant_identifier_names

import 'dart:io';

// const bool prod = bool.fromEnvironment('PROD', defaultValue: false);
const bool prod = true;

String getBASEURL() {
  if (prod) {
    return 'linkup.olildu.dpdns.org/api/v1';
  }
  if (Platform.isAndroid) {
    return '192.168.123.32:9002/api/v1';
  } else {
    // return '161.118.188.217:8000/api/v1';
    return 'localhost:9002/api/v1';
  }
}

// Upgrade to https or wss when on prod
final String BASE_URL = 'http${prod ? "s" : ""}://${getBASEURL()}';
final String WS_BASE_URL = 'ws${prod ? "s" : ""}://${getBASEURL()}/ws';


// Test Creds
// tester@linkup.olildu.dpdns.org
// TESTERcreds#40