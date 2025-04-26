import 'package:chargepassv4/models/password.dart';
import 'package:chargepassv4/services/firestore_service.dart';
import 'package:chargepassv4/services/encryption_service.dart';

class PasswordController {
  final FirestoreService _firestoreService = FirestoreService();
  final EncryptionService _encryptionService = EncryptionService();

  // Ya no recibimos userId como parámetro
  Future<void> savePassword(String name, String password) async {
    String encryptedPassword = _encryptionService.encrypt(password);

    PasswordModel passwordModel = PasswordModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      encryptedPassword: encryptedPassword,
      createdAt: DateTime.now(),
      updatedAt: null,
    );

    // Llamamos a la función que agrega la contraseña sin pasar el userId
    await _firestoreService.addPasswordToUserArray(passwordModel);
  }

  Future<List<PasswordModel>> getPasswords() async {
    // No se necesita userId, ya que lo obtenemos dentro de FirestoreService
    return await _firestoreService.getUserPasswordsFromArray();
  }

  Future<void> updatePassword(PasswordModel updatedPassword) async {
    PasswordModel updated = PasswordModel(
      id: updatedPassword.id,
      name: updatedPassword.name,
      encryptedPassword: updatedPassword.encryptedPassword,
      createdAt: updatedPassword.createdAt,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.updatePasswordInUserArray(updated);
  }

  Future<void> deletePassword(String passwordId) async {
    await _firestoreService.deletePasswordFromUserArray(passwordId);
  }

  Future<String> decryptPassword(String encryptedPassword) async {
    return _encryptionService.decrypt(encryptedPassword);
  }
}



// import 'package:chargepassv4/models/password.dart';
// import 'package:chargepassv4/services/firestore_service.dart';
// import 'package:chargepassv4/services/encryption_service.dart';

// class PasswordController {
//   final FirestoreService _firestoreService = FirestoreService();
//   final EncryptionService _encryptionService = EncryptionService();

//   Future<void> savePassword(String userId, String name, String password) async {
//     String encryptedPassword = _encryptionService.encrypt(password);

//     PasswordModel passwordModel = PasswordModel(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       name: name,
//       encryptedPassword: encryptedPassword,
//       createdAt: DateTime.now(),
//       updatedAt: null,
//     );

//     await _firestoreService.addPasswordToUserArray(userId, passwordModel);
//   }

//   Future<List<PasswordModel>> getPasswords(String userId) async {
//     return await _firestoreService.getUserPasswordsFromArray(userId);
//   }

//   Future<void> updatePassword(String userId, PasswordModel updatedPassword) async {
//     PasswordModel updated = PasswordModel(
//       id: updatedPassword.id,
//       name: updatedPassword.name,
//       encryptedPassword: updatedPassword.encryptedPassword,
//       createdAt: updatedPassword.createdAt,
//       updatedAt: DateTime.now(),
//     );

//     await _firestoreService.updatePasswordInUserArray(userId, updated);
//   }

//   Future<void> deletePassword(String userId, String passwordId) async {
//     await _firestoreService.deletePasswordFromUserArray(userId, passwordId);
//   }

//   Future<String> decryptPassword(String encryptedPassword) async {
//     return _encryptionService.decrypt(encryptedPassword);
//   }
// }
