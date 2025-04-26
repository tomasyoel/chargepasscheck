import 'package:chargepassv4/controllers/password_controller.dart';
import 'package:chargepassv4/models/password.dart';
import 'package:chargepassv4/services/firebase_auth_service.dart';
import 'package:chargepassv4/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late PasswordController _passwordController;

  @override
  void initState() {
    super.initState();
    _passwordController = PasswordController();
  }

  Future<void> _logout() async {
    await Provider.of<FirebaseAuthService>(context, listen: false).signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
  
  void _openPasswordModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return PasswordModalContent(
          passwordController: _passwordController,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<FirebaseAuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final user = authService.getCurrentUser();
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Contraseñas"),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<List<PasswordModel>>(
        future: _passwordController.getPasswords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No hay contraseñas guardadas",
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final password = snapshot.data![index];
              return Card(
                color: isDarkMode ? Colors.grey[900] : Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    password.name,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  // subtitle: Text(
                  //   "Creado: ${DateFormat.yMd().add_jm().format(password.createdAt)}"
                  //   "${password.updatedAt != null ? "\nModificado: ${DateFormat.yMd().add_jm().format(password.updatedAt!)}" : ""}",
                  //   style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                  // ),
                  subtitle: Text(
                      "Creado: ${DateFormat.yMd().add_jm().format(password.createdAt.subtract(const Duration(hours: 5)))}"
                      "${password.updatedAt != null ? "\nModificado: ${DateFormat.yMd().add_jm().format(password.updatedAt!.subtract(const Duration(hours: 5)))}" : ""}",
                      style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
                    ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        color: isDarkMode ? Colors.blue : Colors.blue.shade900,
                        onPressed: () async {
                          String decrypted = await _passwordController.decryptPassword(password.encryptedPassword);
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Contraseña"),
                              content: Text(decrypted),
                              actions: [
                                TextButton(
                                  child: const Text("OK"),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () async {
                     
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Eliminar Contraseña"),
                              content: Text("¿Estás seguro de eliminar la contraseña de ${password.name}?"),
                              actions: [
                                TextButton(
                                  child: const Text("Cancelar"),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                                TextButton(
                                  child: const Text("Eliminar"),
                                  onPressed: () async {
                                    await _passwordController.deletePassword(password.id);
                                    Navigator.of(ctx).pop();
                                    // Recargar la vista
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: isDarkMode ? Colors.blue : Colors.blue.shade900,
        onPressed: _openPasswordModal,
        label: const Text("Generar Pass"),
        icon: const Icon(Icons.lock),
      ),
    );
  }
}


class PasswordModalContent extends StatefulWidget {
  final PasswordController passwordController;

  const PasswordModalContent({
    Key? key,
    required this.passwordController,
  }) : super(key: key);

  @override
  _PasswordModalContentState createState() => _PasswordModalContentState();
}

class _PasswordModalContentState extends State<PasswordModalContent> {
  String _password = "";
  String _name = "";
  bool _isTokenUnique = false;
  final TextEditingController _passwordControllerText = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  @override
  void dispose() {
    _passwordControllerText.dispose();
    super.dispose();
  }

  bool _meetsLength(String p) => p.length >= 8;
  bool _hasUppercase(String p) => p.contains(RegExp(r'[A-Z]'));
  bool _hasLowercase(String p) => p.contains(RegExp(r'[a-z]'));
  bool _hasDigit(String p) => p.contains(RegExp(r'\d'));
  bool _hasSymbol(String p) => p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

  void _generatePassword() {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*';
    final rand = chars.split('')..shuffle();
    final pass = rand.take(16).join();
    setState(() {
      _password = pass;
      _passwordControllerText.text = _password;
    });
  }

  Future<void> _savePassword() async {
    if (_name.isEmpty || (!_isTokenUnique && !_isPasswordValid(_password))) return;

    await widget.passwordController.savePassword(_name, _password);

    setState(() {
      _password = '';
      _name = '';
      _passwordControllerText.text = '';
    });

    Navigator.of(context).pop(); 
  }

  bool _isPasswordValid(String p) =>
      _meetsLength(p) && _hasUppercase(p) && _hasLowercase(p) && _hasDigit(p) && _hasSymbol(p);

  Widget _buildRule(bool met, String label) {
    return Row(
      children: [
        Icon(met ? Icons.check_circle : Icons.cancel,
            color: met ? Colors.green : Colors.red, size: 18),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    //final themeProvider = Provider.of<ThemeProvider>(context);
    //final isDarkMode = themeProvider.isDarkMode;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.6,
      builder: (BuildContext context, ScrollController scrollController) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Generar o guardar contraseña', style: TextStyle(fontSize: 18)),
              TextField(
                onChanged: (val) => setState(() => _name = val),
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _passwordControllerText,
                      onChanged: (value) {
                        setState(() {
                          _password = value;
                        });
                      },
                      readOnly: !_isTokenUnique,
                      decoration: const InputDecoration(labelText: 'Contraseña'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isTokenUnique ? null : _generatePassword,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _isTokenUnique,
                    onChanged: (bool? value) {
                      setState(() {
                        _isTokenUnique = value ?? false;
                        if (_isTokenUnique) {
                          _password = '';
                          _passwordControllerText.text = '';
                        } else {
                          _generatePassword();
                        }
                      });
                    },
                  ),
                  Text('Token único'),
                ],
              ),
              const SizedBox(height: 20),
              if (!_isTokenUnique) ...[
                _buildRule(_meetsLength(_password), 'Al menos 8 caracteres'),
                _buildRule(_hasUppercase(_password), 'Una letra mayúscula'),
                _buildRule(_hasLowercase(_password), 'Una letra minúscula'),
                _buildRule(_hasDigit(_password), 'Un número'),
                _buildRule(_hasSymbol(_password), 'Un símbolo'),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_isTokenUnique && _name.isNotEmpty) || (_isPasswordValid(_password) && _name.isNotEmpty) 
                         ? _savePassword 
                         : null,
                child: const Text("Guardar Contraseña"),
              ),
            ],
          ),
        );
      },
    );
  }
}


// Future<void> _logout() async {
//     await Provider.of<FirebaseAuthService>(context, listen: false).signOut();
//     Navigator.pushReplacementNamed(context, '/login');
//   }


// import 'package:chargepassv4/controllers/password_controller.dart';
// import 'package:chargepassv4/models/password.dart';
// import 'package:chargepassv4/services/firebase_auth_service.dart';
// import 'package:chargepassv4/providers/theme_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';

// class HomeView extends StatefulWidget {
//   const HomeView({Key? key}) : super(key: key);

//   @override
//   _HomeViewState createState() => _HomeViewState();
// }

// class _HomeViewState extends State<HomeView> {
//   late PasswordController _passwordController;
//   late String userId;

//   String _password = "";
//   String _name = "";

//   @override
//   void initState() {
//     super.initState();
//     _passwordController = PasswordController();
//   }

//   bool _meetsLength(String p) => p.length >= 8;
//   bool _hasUppercase(String p) => p.contains(RegExp(r'[A-Z]'));
//   bool _hasLowercase(String p) => p.contains(RegExp(r'[a-z]'));
//   bool _hasDigit(String p) => p.contains(RegExp(r'\d'));
//   bool _hasSymbol(String p) => p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

//   Future<void> _generatePassword() async {
//     const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*';
//     final rand = chars.split('')..shuffle();
//     final pass = rand.take(16).join();
//     setState(() => _password = pass);
//   }

//   Future<void> _savePassword() async {
//   if (_name.isEmpty || !_isPasswordValid(_password)) return;

//   await _passwordController.savePassword(userId, _name, _password);

//   setState(() {
//     _password = '';
//     _name = '';
//   });

//   Navigator.of(context).pop(); // Cierra el modal
// }


//   bool _isPasswordValid(String p) =>
//       _meetsLength(p) && _hasUppercase(p) && _hasLowercase(p) && _hasDigit(p) && _hasSymbol(p);

//   void _openPasswordModal() {
//     showDialog(
//       context: context,
//       builder: (ctx) {
//         final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
//         final isDarkMode = themeProvider.isDarkMode;

//         return AlertDialog(
//           backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           title: Text('Nueva Contraseña', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   onChanged: (val) => setState(() => _name = val),
//                   decoration: const InputDecoration(labelText: 'Nombre'),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: TextEditingController(text: _password),
//                         readOnly: true,
//                         decoration: const InputDecoration(labelText: 'Contraseña'),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.refresh),
//                       onPressed: _generatePassword,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 _buildRule(_meetsLength(_password), 'Al menos 8 caracteres'),
//                 _buildRule(_hasUppercase(_password), 'Una letra mayúscula'),
//                 _buildRule(_hasLowercase(_password), 'Una letra minúscula'),
//                 _buildRule(_hasDigit(_password), 'Un número'),
//                 _buildRule(_hasSymbol(_password), 'Un símbolo'),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: _isPasswordValid(_password) ? _savePassword : null,
//               child: const Text("Guardar"),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildRule(bool met, String label) {
//     return Row(
//       children: [
//         Icon(met ? Icons.check_circle : Icons.cancel,
//             color: met ? Colors.green : Colors.red, size: 18),
//         const SizedBox(width: 6),
//         Text(label),
//       ],
//     );
//   }

//   Future<void> _logout() async {
//     await Provider.of<FirebaseAuthService>(context, listen: false).signOut();
//     Navigator.pushReplacementNamed(context, '/login');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authService = Provider.of<FirebaseAuthService>(context);
//     final themeProvider = Provider.of<ThemeProvider>(context);
//     final isDarkMode = themeProvider.isDarkMode;

//     final user = authService.getCurrentUser();
//     if (user == null) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     userId = user.uid;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mis Contraseñas"),
//         actions: [
//           IconButton(
//             icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
//             onPressed: () => themeProvider.toggleTheme(),
//           ),
//           IconButton(
//             icon: const Icon(Icons.exit_to_app),
//             onPressed: _logout,
//           ),
//         ],
//       ),
//       body: FutureBuilder<List<PasswordModel>>(
//         future: _passwordController.getPasswords(userId),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(
//               child: Text(
//                 "No hay contraseñas guardadas",
//                 style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
//               ),
//             );
//           }

//           return ListView.builder(
//             itemCount: snapshot.data!.length,
//             itemBuilder: (context, index) {
//               final password = snapshot.data![index];
//               return Card(
//                 color: isDarkMode ? Colors.grey[900] : Colors.white,
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: ListTile(
//                   title: Text(
//                     password.name,
//                     style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
//                   ),
//                   subtitle: Text(
//                     "Creado: ${DateFormat.yMd().add_jm().format(password.createdAt)}"
//                     "${password.updatedAt != null ? "\nModificado: ${DateFormat.yMd().add_jm().format(password.updatedAt!)}" : ""}",
//                     style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
//                   ),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.visibility),
//                     color: isDarkMode ? Colors.blue : Colors.blue.shade900,
//                     onPressed: () async {
//                       String decrypted = await _passwordController.decryptPassword(password.encryptedPassword);
//                       showDialog(
//                         context: context,
//                         builder: (ctx) => AlertDialog(
//                           title: const Text("Contraseña"),
//                           content: Text(decrypted),
//                           actions: [
//                             TextButton(
//                               child: const Text("OK"),
//                               onPressed: () => Navigator.of(ctx).pop(),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: isDarkMode ? Colors.blue : Colors.blue.shade900,
//         onPressed: _openPasswordModal,
//         label: const Text("Generar Pass"),
//         icon: const Icon(Icons.lock),
//       ),
//     );
//   }
// }