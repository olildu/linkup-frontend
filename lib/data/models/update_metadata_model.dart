class UpdateMetadataModel {
  // Core
  final String? universityMajor;
  final int? universityYear;

  final String? profilePicture;

  final String? about;

  final String? currentlyStaying;
  final String? hometown;

  // Interests
  final int? height;
  final int? weight;

  final String? religion;

  final String? smokingInfo;
  final String? drinkingInfo;

  final String? lookingFor;

  UpdateMetadataModel({
    this.universityMajor,
    this.universityYear,
    this.profilePicture,
    this.about,
    this.currentlyStaying,
    this.hometown,
    this.height,
    this.weight,
    this.religion,
    this.smokingInfo,
    this.drinkingInfo,
    this.lookingFor,
  });

  factory UpdateMetadataModel.fromJson(Map<String, dynamic> json) {
    return UpdateMetadataModel(
      universityMajor: json['university_major'] as String?,
      universityYear: json['university_year'] as int?,
      profilePicture: json['profile_picture'] as String?,
      about: json['about'] as String?,
      currentlyStaying: json['currently_staying'] as String?,
      hometown: json['hometown'] as String?,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      religion: json['religion'] as String?,
      smokingInfo: json['smoking_info'] as String?,
      drinkingInfo: json['drinking_info'] as String?,
      lookingFor: json['looking_for'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'university_major': universityMajor,
      'university_year': universityYear,
      'profile_picture': profilePicture,
      'about': about,
      'currently_staying': currentlyStaying,
      'hometown': hometown,
      'height': height,
      'weight': weight,
      'religion': religion,
      'smoking_info': smokingInfo,
      'drinking_info': drinkingInfo,
      'looking_for': lookingFor,
    };
  }
}
