import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:linkup/data/models/update_metadata_model.dart';
import 'package:linkup/logic/bloc/profile/own/profile_bloc.dart';
import 'package:provider/provider.dart';

class SignUpDataParser {
  static late UpdateMetadataModel _data;
  static late UpdateMetadataModel _latestData;

  static final String debugTag = "SignUpDataParser";

  static void initialize(BuildContext context) {
    final state = context.read<ProfileBloc>().state;
    if (state is ProfileLoaded) {
      _data = UpdateMetadataModel.fromJson(state.user.toJson());
      _latestData = UpdateMetadataModel.fromJson(state.user.toJson());
      log("SignUpDataParser initialized", name: debugTag);
    } else {
      throw Exception("ProfileBloc is not loaded");
    }
  }

  static void updateField({
    String? interestedGender,
    String? universityMajor,
    int? universityYear,
    List<String>? photos,
    String? profilePicture,
    String? about,
    String? currentlyStaying,
    String? hometown,
    int? height,
    int? weight,
    String? religion,
    String? smokingInfo,
    String? drinkingInfo,
    bool? drinkingStatus,
    bool? smokingStatus,
    String? lookingFor,
  }) {
    _data = UpdateMetadataModel(
      universityMajor: universityMajor ?? _data.universityMajor,
      universityYear: universityYear ?? _data.universityYear,
      profilePicture: profilePicture ?? _data.profilePicture,
      about: about ?? _data.about,
      currentlyStaying: currentlyStaying ?? _data.currentlyStaying,
      hometown: hometown ?? _data.hometown,
      height: height ?? _data.height,
      weight: weight ?? _data.weight,
      religion: religion ?? _data.religion,
      smokingInfo: smokingInfo ?? _data.smokingInfo,
      drinkingInfo: drinkingInfo ?? _data.drinkingInfo,
      lookingFor: lookingFor ?? _data.lookingFor,
    );
  }

  static void printFormattedData() {
    final json = _data.toJson();
    log(json.toString(), name: debugTag);
  }

  static void updateData(BuildContext context) {
    final current = _data.toJson();
    final original = _latestData.toJson();

    final changedFields = <String, dynamic>{};

    for (final key in current.keys) {
      if (current[key] != original[key]) {
        changedFields[key] = current[key];
      }
    }

    if (changedFields.isEmpty) {
      log("No changes detected", name: debugTag);
    } else {
      log("Changed fields model: $changedFields", name: debugTag);
      context.read<ProfileBloc>().add(ProfileUpdateEvent(userUpdatedModel: _data));
    }
  }

  static UpdateMetadataModel get data => _data;
}
