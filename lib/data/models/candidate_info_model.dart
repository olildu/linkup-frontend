import 'package:flutter/material.dart';
import 'package:linkup/data/models/match_candidate_model.dart';
import 'package:linkup/data/models/user_model.dart';

class CandidateInfoModel {
  final int? id;
  final int? height;
  final int? weight;
  final String? religion;
  final String? smokingInfo;
  final String? drinkingInfo;
  final String? lookingFor;
  final String? gender;

  const CandidateInfoModel({
    this.id,
    this.height,
    this.weight,
    this.religion,
    this.smokingInfo,
    this.drinkingInfo,
    this.lookingFor,
    this.gender,
  });

  factory CandidateInfoModel.fromJson(Map<String, dynamic> json) {
    return CandidateInfoModel(
      id: json['id'] as int,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      religion: json['religion'] as String?,
      smokingInfo: json['smoking_info'] as String?,
      drinkingInfo: json['drinking_info'] as String?,
      lookingFor: json['looking_for'] as String?,
      gender: json['gender'] as String,
    );
  }

  factory CandidateInfoModel.fromMatchCandidate(MatchCandidateModel candidate) {
    return CandidateInfoModel(
      id: candidate.id,
      height: candidate.height,
      weight: candidate.weight,
      religion: candidate.religion,
      smokingInfo: candidate.smokingInfo,
      drinkingInfo: candidate.drinkingInfo,
      lookingFor: candidate.lookingFor,
      gender: candidate.gender,
    );
  }

  factory CandidateInfoModel.fromUserModel(UserModel user) {
    return CandidateInfoModel(
      height: user.height,
      weight: user.weight,
      religion: user.religion,
      smokingInfo: user.smokingInfo,
      drinkingInfo: user.drinkingInfo,
      lookingFor: user.lookingFor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'weight': weight,
      'religion': religion,
      'smoking_info': smokingInfo,
      'drinking_info': drinkingInfo,
      'looking_for': lookingFor,
    }..removeWhere((key, data) => data == null); 
  }

  Map<String, Map<String, dynamic>> asIconMap({
    bool showGender = true,
  }) {
    return {
      'gender': { 
        'icon' : gender == "Male" ? Icons.man_rounded : Icons.woman_rounded,
        'value' : gender,
        "index": -1,
        "title" : "Gender",
      },
      'height': {
        'icon': Icons.straighten_rounded,
        'value': height != null ? '$height cm' : null,
        "index": 10,
        "title": "Height",
      },
      'weight': {
        'icon': Icons.monitor_weight,
        'value': weight != null ? '$weight kg' : null,
        "index": 11,
        "title": "Weight",
      },
      'religion': {
        'icon': Icons.church_rounded,
        'value': religion,
        "index": 12,
        "title": "Religion",
      },
      'smoking': {
        'icon': Icons.smoking_rooms_rounded,
        'value': smokingInfo,
        "index": 13,
        "title": "Smoking",
      },
      'drinking': {
        'icon': Icons.local_bar_rounded,
        'value': drinkingInfo,
        "index": 14,
        "title": "Drinking",
      },
      'looking_for': {
        'icon': Icons.favorite_outline_rounded,
        'value': lookingFor,
        "index": 15,
        "title": "Looking For",
      },
    }..remove(showGender ? "" : 'gender'); 
  }
}
