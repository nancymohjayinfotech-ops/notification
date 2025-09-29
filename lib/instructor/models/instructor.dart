class Instructor {
  final String email;
  final String password;
  final String name;

  Instructor({required this.email, required this.password, required this.name});
}

// Fixed instructor credentials for now
List<Instructor> registeredInstructors = [
  Instructor(
    email: 'instructor1@example.com',
    password: 'password123',
    name: 'John Smith',
  ),
];
