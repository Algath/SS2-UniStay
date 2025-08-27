import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../viewmodels/add_property_vm.dart';

class AddPropertyPage extends StatefulWidget {
  static const route = '/add-property';
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _address = TextEditingController();
  bool _saving = false;
  final _vm = AddPropertyViewModel();

  @override
  void dispose() {
    _title.dispose(); _price.dispose(); _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _vm.addProperty(
      ownerUid: uid,
      title: _title.text.trim(),
      price: num.tryParse(_price.text.trim()) ?? 0,
      address: _address.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Title'), validator: (v)=>v==null||v.isEmpty?'Required':null),
                const SizedBox(height: 12),
                TextFormField(controller: _price, decoration: const InputDecoration(labelText: 'Price (CHF)'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Full address'), validator: (v)=>v==null||v.isEmpty?'Required':null),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
