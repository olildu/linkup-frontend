class UserModel {
  final int id; 

  final String username;
  final String gender;
  final int universityId;
  final String profilePicture;

  final DateTime dob;
  final String interestedGender;

  final String universityMajor;
  final int universityYear;

  final List<String> photos;
  final String about;

  final String currentlyStaying; 
  final String hometown;

  final int? height;
  final int? weight;

  final String? religion; 

  final String? smokingInfo; 
  final String? drinkingInfo;

  final String? lookingFor; 

  UserModel({
    required this.id,
    required this.username,
    required this.gender,
    required this.universityId,
    required this.profilePicture,
    required this.dob,
    required this.interestedGender,
    required this.universityMajor,
    required this.universityYear,
    required this.photos,
    required this.about,
    required this.currentlyStaying,
    required this.hometown,
    this.height,
    this.weight,
    this.religion,
    this.smokingInfo,
    this.drinkingInfo,
    this.lookingFor,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      gender: json['gender'],
      universityId: json['university_id'],
      profilePicture: json['profile_picture'],
      dob: DateTime.parse(json['dob']),
      interestedGender: json['interested_gender'],
      universityMajor: json['university_major'],
      universityYear: json['university_year'],
      photos: List<String>.from(json['photos']),
      about: json['about'],
      currentlyStaying: json['currently_staying'],
      hometown: json['hometown'],
      height: json['height'],
      weight: json['weight'],
      religion: json['religion'],
      smokingInfo: json['smoking_info'],
      drinkingInfo: json['drinking_info'],
      lookingFor: json['looking_for'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'gender': gender,
      'university_id': universityId,
      'profile_picture': profilePicture,
      'dob': dob.toIso8601String(),
      'interested_gender': interestedGender,
      'university_major': universityMajor,
      'university_year': universityYear,
      'photos': photos,
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
