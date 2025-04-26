import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chargepassv4/models/password.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

 
  String getCurrentUserId() {
    User? user = _auth.currentUser;
    return user?.uid ?? '';
  }

 
  Future<DocumentSnapshot?> _getUserDocByEmail() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.email == null) {
      throw Exception('Usuario no autenticado o sin email');
    }
    
    String email = currentUser.email!;
    
   
    QuerySnapshot snapshot = await _firestore
        .collection('usuarios')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      return null;
    }
    
    return snapshot.docs.first;
  }


  Future<void> addPasswordToUserArray(PasswordModel password) async {
    DocumentSnapshot? userDoc = await _getUserDocByEmail();
    
    if (userDoc == null) {
    
      throw Exception('Usuario no encontrado en la base de datos');
    }
    
    String userDocId = userDoc.id;
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
    
    if (userData != null && userData.containsKey('passwords')) {
   
      await _firestore.collection('usuarios').doc(userDocId).update({
        'passwords': FieldValue.arrayUnion([password.toMap()]),
      });
    } else {
  
      await _firestore.collection('usuarios').doc(userDocId).update({
        'passwords': [password.toMap()],
      });
    }
  }


  Future<List<PasswordModel>> getUserPasswordsFromArray() async {
    DocumentSnapshot? userDoc = await _getUserDocByEmail();
    
    if (userDoc == null) {
      return [];
    }
    
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
    
    if (userData == null || !userData.containsKey('passwords')) {
      return [];
    }
    
    List<dynamic> passwords = userData['passwords'] ?? [];
    
    return passwords
        .map((p) => PasswordModel.fromMap(Map<String, dynamic>.from(p)))
        .toList();
  }

 
  Future<void> updatePasswordInUserArray(PasswordModel updatedPassword) async {
    DocumentSnapshot? userDoc = await _getUserDocByEmail();
    
    if (userDoc == null) {
      return;
    }
    
    String userDocId = userDoc.id;
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
    
    if (userData == null || !userData.containsKey('passwords')) {
      return;
    }

    List<dynamic> passwords = userData['passwords'];
    List<Map<String, dynamic>> updatedList = [];
    
    
    for (var p in passwords) {
      Map<String, dynamic> entry = Map<String, dynamic>.from(p);
      if (entry['id'] == updatedPassword.id) {
        updatedList.add(updatedPassword.toMap());
      } else {
        updatedList.add(entry);
      }
    }

   
    await _firestore.collection('usuarios').doc(userDocId).update({
      'passwords': updatedList,
    });
  }

 
  Future<void> deletePasswordFromUserArray(String passwordId) async {
    DocumentSnapshot? userDoc = await _getUserDocByEmail();
    
    if (userDoc == null) {
      return;
    }
    
    String userDocId = userDoc.id;
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
    
    if (userData == null || !userData.containsKey('passwords')) {
      return;
    }

    List<dynamic> passwords = userData['passwords'];
    List<Map<String, dynamic>> updatedList = [];
    
    
    for (var p in passwords) {
      Map<String, dynamic> entry = Map<String, dynamic>.from(p);
      if (entry['id'] != passwordId) {
        updatedList.add(entry);
      }
    }

   
    await _firestore.collection('usuarios').doc(userDocId).update({
      'passwords': updatedList,
    });
  }
}



// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:chargepassv4/models/password.dart';

// class FirestoreService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<void> addPasswordToUserArray(String userId, PasswordModel password) async {
//     // Verificamos si el documento del usuario ya existe
//     DocumentSnapshot userDoc = await _firestore.collection('usuarios').doc(userId).get();

//     if (!userDoc.exists) {
//       // Si el documento no existe, lo creamos
//       await _firestore.collection('usuarios').doc(userId).set({
//         'passwords': [password.toMap()], // Iniciamos el array de contraseñas con la primera contraseña
//       });
//     } else {
//       // Si el documento ya existe, solo actualizamos el array de contraseñas
//       await _firestore.collection('usuarios').doc(userId).update({
//         'passwords': FieldValue.arrayUnion([password.toMap()]),
//       });
//     }
//   }

//   Future<List<PasswordModel>> getUserPasswordsFromArray(String userId) async {
//     DocumentSnapshot userDoc = await _firestore.collection('usuarios').doc(userId).get();

//     if (!userDoc.exists) return [];

//     List<dynamic> passwords = (userDoc.data() as Map<String, dynamic>)['passwords'] ?? [];

//     return passwords
//         .map((p) => PasswordModel.fromMap(Map<String, dynamic>.from(p)))
//         .toList();
//   }

//   Future<void> updatePasswordInUserArray(String userId, PasswordModel updatedPassword) async {
//     DocumentSnapshot userDoc = await _firestore.collection('usuarios').doc(userId).get();

//     if (!userDoc.exists) return;

//     List<dynamic> passwords = (userDoc.data() as Map<String, dynamic>)['passwords'] ?? [];

//     List<Map<String, dynamic>> updatedList = passwords.map<Map<String, dynamic>>((p) {
//       Map<String, dynamic> entry = Map<String, dynamic>.from(p);
//       if (entry['id'] == updatedPassword.id) {
//         return updatedPassword.toMap();
//       }
//       return entry;
//     }).toList();

//     await _firestore.collection('usuarios').doc(userId).update({'passwords': updatedList});
//   }

//   Future<void> deletePasswordFromUserArray(String userId, String passwordId) async {
//     DocumentSnapshot userDoc = await _firestore.collection('usuarios').doc(userId).get();

//     if (!userDoc.exists) return;

//     List<dynamic> passwords = (userDoc.data() as Map<String, dynamic>)['passwords'] ?? [];

//     List<Map<String, dynamic>> updatedList = passwords
//         .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
//         .where((entry) => entry['id'] != passwordId)
//         .toList();

//     await _firestore.collection('usuarios').doc(userId).update({'passwords': updatedList});
//   }
// }
