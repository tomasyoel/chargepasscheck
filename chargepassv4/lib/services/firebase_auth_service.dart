import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/usuario.dart'; // Asegúrate que el path es correcto

class FirebaseAuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null && userCredential.user!.emailVerified) {
        notifyListeners();
        return userCredential.user;
      } else {
        debugPrint("Correo no verificado");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Error en inicio de sesión: ${e.message}");
      return null;
    }
  }

  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        debugPrint("Correo de verificación enviado");

        // Guardamos solo el correo en Firestore (con ID autogenerado)
        await saveUserToFirestore(user);

        notifyListeners();
        return user;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Error en registro: ${e.message}");
    }
    return null;
  }

  Future<void> saveUserToFirestore(User user) async {
    try {
      final userData = UserModel(email: user.email ?? '');
      await _firestore.collection("usuarios").add(userData.toMap());
      debugPrint("Usuario guardado en Firestore (solo correo)");
    } catch (e) {
      debugPrint("Error guardando usuario en Firestore: $e");
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint("Correo de restablecimiento enviado a $email");
    } on FirebaseAuthException catch (e) {
      debugPrint("Error al enviar correo de restablecimiento: ${e.message}");
      throw e.message ?? "Error desconocido"; 
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}




// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../models/usuario.dart'; // Asegúrate que el path es correcto

// class FirebaseAuthService with ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   User? getCurrentUser() {
//     return _auth.currentUser;
//   }

//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   Future<User?> signInWithEmailAndPassword(String email, String password) async {
//     try {
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       if (userCredential.user != null && userCredential.user!.emailVerified) {
//         notifyListeners();
//         return userCredential.user;
//       } else {
//         debugPrint("Correo no verificado");
//         return null;
//       }
//     } on FirebaseAuthException catch (e) {
//       debugPrint("Error en inicio de sesión: ${e.message}");
//       return null;
//     }
//   }

//   Future<User?> registerWithEmailAndPassword(String email, String password) async {
//     try {
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       User? user = userCredential.user;
//       if (user != null) {
//         await user.sendEmailVerification();
//         debugPrint("Correo de verificación enviado");

//         // Esperamos a que el usuario verifique su email antes de guardarlo en Firestore.
//         // Este paso lo deberías manejar en tu lógica de login luego.

//         notifyListeners();
//         return user;
//       }
//     } on FirebaseAuthException catch (e) {
//       debugPrint("Error en registro: ${e.message}");
//     }
//     return null;
//   }

//   Future<void> saveUserToFirestore(User user) async {
//     try {
//       final userDoc = _firestore.collection("usuarios").doc(user.uid);
//       final userData = UserModel(id: user.uid, email: user.email ?? '');
//       await userDoc.set(userData.toMap());
//       debugPrint("Usuario guardado en Firestore");
//     } catch (e) {
//       debugPrint("Error guardando usuario en Firestore: $e");
//     }
//   }

//   Future<void> signOut() async {
//     await _auth.signOut();
//     notifyListeners();
//   }
// }
