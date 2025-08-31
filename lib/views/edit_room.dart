import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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
  List<DateTimeRange> _availabilityRanges = [];

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
    // Load availability ranges
    final rangesData = m['availabilityRanges'] as List?;
    if (rangesData != null) {
      for (var rangeData in rangesData) {
        if (rangeData is Map<String, dynamic>) {
          final start = rangeData['start'] as Timestamp?;
          final end = rangeData['end'] as Timestamp?;
          if (start != null && end != null) {
            _availabilityRanges.add(DateTimeRange(
              start: start.toDate(),
              end: end.toDate(),
            ));
          }
        }
      }
    }
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
        'availabilityRanges': _availabilityRanges.map((range) => {
          'start': range.start,
          'end': range.end,
        }).toList(),
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final price = num.tryParse(v);
                          if (price == null) return 'Enter valid number';
                          if (price < 200) return 'Price should be at least CHF 200';
                          return null;
                        }),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _sizeSqm, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Size (m²) *'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final size = int.tryParse(v);
                            if (size == null) return 'Enter valid number';
                            if (size < 15) return 'Size should be at least 15 m²';
                            if (size > 500) return 'Size should be less than 500 m²';
                            return null;
                          })),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _rooms, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rooms *'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final rooms = int.tryParse(v);
                            if (rooms == null) return 'Enter valid number';
                            if (rooms < 1) return 'Rooms should be at least 1';
                            if (rooms > 10) return 'Rooms should be less than 10';
                            return null;
                          })),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _baths, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Bathrooms *'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final baths = int.tryParse(v);
                            if (baths == null) return 'Enter valid number';
                            if (baths < 1) return 'Bathrooms should be at least 1';
                            if (baths > 5) return 'Bathrooms should be less than 5';
                            return null;
                          })),
                    ]),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Furnished'),
                      value: _furnished,
                      onChanged: (v) => setState(() => _furnished = v),
                    ),
                    const SizedBox(height: 12),
                    
                    // Availability Section
                    const Text(
                      'Availability *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _EditRoomCalendar(
                        initialRanges: _availabilityRanges,
                        onRangesSelected: (ranges) {
                          setState(() {
                            _availabilityRanges = ranges;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: _save, child: const Text('Save')),
                  ]),
                ),
              ),
            ),
    );
  }
}

class _EditRoomCalendar extends StatefulWidget {
  final List<DateTimeRange> initialRanges;
  final Function(List<DateTimeRange>) onRangesSelected;
  
  const _EditRoomCalendar({
    required this.initialRanges,
    required this.onRangesSelected,
  });

  @override
  State<_EditRoomCalendar> createState() => _EditRoomCalendarState();
}

class _EditRoomCalendarState extends State<_EditRoomCalendar> {
  late DateTime _focusedDay;
  late DateTimeRange? _selectedRange;
  List<DateTimeRange> _availabilityRanges = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _availabilityRanges = List.from(widget.initialRanges);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Edit Availability Ranges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_selectedRange != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedRange = null;
                    });
                  },
                  child: const Text('Clear Selection'),
                ),
              const SizedBox(width: 8),
              if (_selectedRange != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _availabilityRanges.add(_selectedRange!);
                      _selectedRange = null;
                    });
                    widget.onRangesSelected(_availabilityRanges);
                  },
                  child: const Text('Add Range'),
                ),
            ],
          ),
        ),
        Expanded(
                      child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              rangeStartDay: _selectedRange?.start,
              rangeEndDay: _selectedRange?.end,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              rowHeight: 35,
              daysOfWeekHeight: 30,
            onDaySelected: (selectedDay, focusedDay) {
              if (_selectedRange == null) {
                setState(() {
                  _selectedRange = DateTimeRange(start: selectedDay, end: selectedDay);
                  _focusedDay = focusedDay;
                });
                widget.onRangesSelected([DateTimeRange(start: selectedDay, end: selectedDay)]);
              } else {
                final start = _selectedRange!.start;
                final end = selectedDay;
                
                if (start.isAfter(end)) {
                  setState(() {
                    _selectedRange = DateTimeRange(start: end, end: start);
                    _focusedDay = focusedDay;
                  });
                  widget.onRangesSelected([DateTimeRange(start: end, end: start)]);
                } else {
                  setState(() {
                    _selectedRange = DateTimeRange(start: start, end: end);
                    _focusedDay = focusedDay;
                  });
                  widget.onRangesSelected([DateTimeRange(start: start, end: end)]);
                }
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ),
        if (_selectedRange != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selected: ${_selectedRange!.start.day}/${_selectedRange!.start.month}/${_selectedRange!.start.year} → ${_selectedRange!.end.day}/${_selectedRange!.end.month}/${_selectedRange!.end.year}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_availabilityRanges.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Added Ranges (${_availabilityRanges.length})',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._availabilityRanges.asMap().entries.map((entry) {
                  final index = entry.key;
                  final range = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${range.start.day}/${range.start.month}/${range.start.year} → ${range.end.day}/${range.end.month}/${range.end.year}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _availabilityRanges.removeAt(index);
                            });
                            widget.onRangesSelected(_availabilityRanges);
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.red[600],
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}


