import 'dart:math';

class PasswordGenerator {
  static String generate({int length = 16}) {
    const String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()";
    Random random = Random();
    
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
