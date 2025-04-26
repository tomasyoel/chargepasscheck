// import 'package:chargepass/controllers/firestore_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class CustomerProfilePage extends StatefulWidget {
//   const CustomerProfilePage({Key? key}) : super(key: key);

//   @override
//   _CustomerProfilePageState createState() => _CustomerProfilePageState();
// }

// class _CustomerProfilePageState extends State<CustomerProfilePage> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final User? user = FirebaseAuth.instance.currentUser;

//   final TextEditingController _nombreController = TextEditingController();
//   final TextEditingController _apellidoController = TextEditingController();
//   final TextEditingController _nroCelularController = TextEditingController();
//   final TextEditingController _edadController = TextEditingController();
//   String? _photoUrl;

//   final _formKey = GlobalKey<FormState>();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     if (user != null) {
//       DocumentSnapshot userDoc = await _firestoreService.getUserById(user!.uid);
//       var userData = userDoc.data() as Map<String, dynamic>;

//       setState(() {
//         _nombreController.text = userData['nombre'] ?? '';
//         _apellidoController.text = userData['apellido'] ?? '';
//         _nroCelularController.text = userData['nro_celular'] ?? '';
//         _photoUrl = userData['photoUrl'];
//         _edadController.text = userData['edad']?.toString() ?? '';
//       });
//     }
//   }

//   Future<void> _updateUserData() async {
//     if (user != null && _formKey.currentState!.validate()) {
//       Map<String, dynamic> updatedData = {
//         'nombre': _nombreController.text,
//         'apellido': _apellidoController.text,
//         'nro_celular': _nroCelularController.text,
//         'photoUrl': _photoUrl,
//         'edad': int.tryParse(_edadController.text) ?? 0,
//       };
//       await _firestoreService.updateUser(user!.uid, updatedData);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Datos Actualizados')),
//       );
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Perfil del Cliente'),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               CircleAvatar(
//                 radius: 50,
//                 backgroundColor: Colors.grey[200],
//                 backgroundImage: _photoUrl != null
//                     ? NetworkImage(_photoUrl!)
//                     : null,
//                 child: _photoUrl == null
//                     ? const Icon(
//                         Icons.person,
//                         size: 50,
//                         color: Colors.grey,
//                       )
//                     : null,
//               ),
//               const SizedBox(height: 20),
//               _buildTextField('Nombre', _nombreController),
//               _buildTextField('Apellido', _apellidoController),
//               _buildTextField('Número de Celular', _nroCelularController),
//               _buildTextField('Edad', _edadController, keyboardType: TextInputType.number),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _updateUserData,
//                 child: const Text('Guardar'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField(String label, TextEditingController controller,
//       {TextInputType keyboardType = TextInputType.text}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8.0),
//           ),
//         ),
//         keyboardType: keyboardType,
//       ),
//     );
//   }
// }
