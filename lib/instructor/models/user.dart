class User {
  final String email;
  final String password;
  final String fullName;

  User({required this.email, required this.password, required this.fullName});
}

List<User> registeredUsers = [];
