import 'package:bcrypt/bcrypt.dart';

void main(List<String> args) {
  final password = args.isNotEmpty ? args[0] : 'password123';
  final hash = BCrypt.hashpw(password, BCrypt.gensalt());
  print('Password: $password');
  print('Hash: $hash');
} 