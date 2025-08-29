import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditRoomPage extends StatefulWidget {
  final String roomId;
  const EditRoomPage({super.key, required this.roomId});

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _sizeSqm = TextEditingController();
  final _rooms = TextEditingController();
  final _baths = TextEditingController();
  bool _furnished = false;
  bool _loading = true;
  DateTime? _availFrom, _availTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
    final m = doc.data() ?? {};
    _title.text = (m['title'] ?? '') as String;
    _price.text = ((m['price'] ?? 0).toString());
    _sizeSqm.text = ((m['sizeSqm'] ?? 0).toString());
    _rooms.text = ((m['rooms'] ?? 1).toString());
    _baths.text = ((m['bathrooms'] ?? 1).toString());
    _furnished = (m['furnished'] ?? false) as bool;
    final tsFrom = m['availabilityFrom'];
    final tsTo = m['availabilityTo'];
    _availFrom = tsFrom is Timestamp ? tsFrom.toDate() : null;
    _availTo = tsTo is Timestamp ? tsTo.toDate() : null;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).set({
        'title': _title.text.trim(),
        'price': num.tryParse(_price.text.trim()) ?? 0,
        'sizeSqm': int.tryParse(_sizeSqm.text.trim()) ?? 0,
        'rooms': int.tryParse(_rooms.text.trim()) ?? 1,
        'bathrooms': int.tryParse(_baths.text.trim()) ?? 1,
        'furnished': _furnished,
        'availabilityFrom': _availFrom,
        'availabilityTo': _availTo,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing updated')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  void dispose() {
    _title.dispose(); _price.dispose(); _sizeSqm.dispose(); _rooms.dispose(); _baths.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Listing')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(children: [
                    TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Title *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (CHF) *'),
                        validator: (v) => num.tryParse(v ?? '') == null ? 'Enter number' : null),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _sizeSqm, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Size (m²) *'),
                          validator: (v) => int.tryParse(v ?? '') == null ? 'Required' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _rooms, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rooms *'),
                          validator: (v) => int.tryParse(v ?? '') == null ? 'Required' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _baths, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bathrooms *'),
                          validator: (v) => int.tryParse(v ?? '') == null ? 'Required' : null)),
                    ]),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(value: _furnished, onChanged: (v) => setState(() => _furnished = v), title: const Text('Furnished')),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final d = await showDateRangePicker(
                          context: context,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365)),
                          helpText: 'Set availability range',
                        );
                        if (d != null) {
                          setState(() {
                            _availFrom = d.start;
                            _availTo = d.end;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(
                        _availFrom == null
                            ? 'Set availability'
                            : '${_availFrom!.toString().split(" ").first} → ${_availTo!.toString().split(" ").first}',
                      ),
                    ),
                    ElevatedButton(onPressed: _save, child: const Text('Save')),
                  ]),
                ),
              ),
            ),
    );
  }
}


