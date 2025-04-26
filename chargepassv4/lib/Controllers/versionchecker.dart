import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class VersionCheckerService {
  static final VersionCheckerService _instance = VersionCheckerService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;


  factory VersionCheckerService() {
    return _instance;
  }

  VersionCheckerService._internal();


  void startVersionListener(Function onVersionMismatch) async {
    if (_initialized) return;
    _initialized = true;

   
    final packageInfo = await PackageInfo.fromPlatform();
    String currentVersion = packageInfo.version;

  
    _firestore.collection('version').doc('n4gJAQPr09uWNTFKaMOP').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        String minAppVersion = snapshot.data()?['versionmin'] ?? '';

        debugPrint('Versión mínima requerida desde Firestore (escuchada): $minAppVersion');
        debugPrint('Versión actual de la aplicación: $currentVersion');

      
        if (!_isVersionValid(currentVersion, minAppVersion)) {
          onVersionMismatch();
        }
      } else {
        debugPrint('Advertencia: El documento de versión mínima no existe en Firestore');
      }
    });
  }

  Future<bool> isVersionValid() async {
    try {

      final DocumentSnapshot doc = await _firestore.collection('version').doc('n4gJAQPr09uWNTFKaMOP').get();

      if (!doc.exists) {
        debugPrint('Advertencia: El documento de versión mínima no existe en Firestore');
        return true; 
      }

      // Obtener el campo 'versionmin' desde Firestore
      String minAppVersion = doc['versionmin'] ?? '';
      if (minAppVersion.isEmpty) {
        debugPrint('Advertencia: El campo versionmin no se encontró en Firestore');
        return true; 
      }

     
      final packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      debugPrint('Verificando compatibilidad de versiones:');
      debugPrint('Versión mínima requerida desde Firestore: $minAppVersion');
      debugPrint('Versión actual de la aplicación: $currentVersion');

      bool isValid = _isVersionValid(currentVersion, minAppVersion);
      debugPrint('Resultado de verificación de versión: ${isValid ? 'válida' : 'actualización requerida'}');

      return isValid;
    } catch (e, stackTrace) {
      debugPrint('Error al verificar la versión desde Firestore: $e');
      debugPrint('Stack trace: $stackTrace');
      return true;
    }
  }

  bool _isVersionValid(String currentVersion, String minVersion) {
    try {
      List<int> current = currentVersion.split('.').map((e) => int.parse(e.trim())).toList();
      List<int> minimum = minVersion.split('.').map((e) => int.parse(e.trim())).toList();


      while (current.length < minimum.length) {
        current.add(0);
      }
      while (minimum.length < current.length) {
        minimum.add(0);
      }

      for (int i = 0; i < current.length; i++) {
        if (current[i] > minimum[i]) return true;
        if (current[i] < minimum[i]) return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error al comparar versiones: $e');
      return true;
    }
  }
}
