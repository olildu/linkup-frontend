class MatchesConnectionModel {
  final int id;
  final String username;
  final String profilePicture;

  MatchesConnectionModel({
    required this.id,
    required this.username,
    required this.profilePicture,
  });

  factory MatchesConnectionModel.fromJson(Map<String, dynamic> json) {
    return MatchesConnectionModel(
      id: json['id'],
      username: json['username'],
      profilePicture: json['profile_picture'],
    );
  }
}