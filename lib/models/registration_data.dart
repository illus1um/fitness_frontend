class RegistrationData {
  final String username;
  final String? email;
  final String password;
  final String? firstName;
  final String? lastName;
  final bool? gender;

  int? age;
  int? height;
  int? weight;
  String? trainingProgram;
  String? location;
  String? difficulty;

  RegistrationData({
    required this.username,
    this.email,
    required this.password,
    this.firstName,
    this.lastName,
    this.gender,
    this.age,
    this.height,
    this.weight,
    this.trainingProgram,
    this.location,
    this.difficulty,
  });
}
