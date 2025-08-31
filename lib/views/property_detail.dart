import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unistay/models/room.dart';
import 'package:table_calendar/table_calendar.dart';

class PropertyDetailPage extends StatelessWidget {
  final String roomId;
  const PropertyDetailPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final room = Room.fromFirestore(snap.data!);
            final img = room.photos.isNotEmpty ? room.photos.first : null;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: img == null
                      ? Container(height: 200, color: Colors.grey.shade200)
                      : Image.network(img, height: 220, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text(room.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('CHF ${room.price}/month · ${room.sizeSqm} m² · ${room.rooms} rooms',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                const Text('Address', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${room.street} ${room.houseNumber}'),
                    Text('${room.postcode} ${room.city}'),
                    Text(room.country),
                  ],
                ),
                const SizedBox(height: 16),
                if (room.availabilityFrom != null || room.availabilityTo != null) ...[
                  const Text('Availability', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    room.availabilityFrom != null && room.availabilityTo != null
                        ? '${room.availabilityFrom!.toString().split(" ").first} → ${room.availabilityTo!.toString().split(" ").first}'
                        : room.availabilityFrom != null
                            ? 'From ${room.availabilityFrom!.toString().split(" ").first}'
                            : 'Until ${room.availabilityTo!.toString().split(" ").first}',
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(room.description.isNotEmpty ? room.description : '—'),
                const SizedBox(height: 16),
                
                // Calendar View
                const Text('Availability Calendar', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _AvailabilityCalendar(
                  room: room,
                  isOwner: currentUser?.uid == room.ownerUid,
                ),
                const SizedBox(height: 16),
                
                // Book This Period button (only for students)
                if (currentUser?.uid != room.ownerUid) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
                          return;
                        }
                        final now = DateTime.now();
                        final fromLim = room.availabilityFrom ?? now;
                        final toLim = room.availabilityTo ?? now.add(const Duration(days: 365));
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: fromLim.isAfter(now) ? fromLim : now,
                          lastDate: toLim,
                          helpText: 'Select stay period',
                        );
                        if (range == null) return;
                        // Guard: chosen range must be inside availability
                        if ((room.availabilityFrom != null && range.start.isBefore(room.availabilityFrom!)) ||
                            (room.availabilityTo != null && range.end.isAfter(room.availabilityTo!))) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected dates are outside availability')));
                          return;
                        }
                        final data = {
                          'roomId': room.id,
                          'ownerUid': room.ownerUid,
                          'studentUid': user.uid,
                          'from': Timestamp.fromDate(range.start),
                          'to': Timestamp.fromDate(range.end),
                          'status': 'pending',
                          'createdAt': FieldValue.serverTimestamp(),
                        };
                        try {
                          await FirebaseFirestore.instance.collection('bookings').add(data);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking request sent')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E56CF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Book This Period'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AvailabilityCalendar extends StatefulWidget {
  final Room room;
  final bool isOwner;
  
  const _AvailabilityCalendar({
    required this.room,
    required this.isOwner,
  });

  @override
  State<_AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<_AvailabilityCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late DateTimeRange? _selectedRange;
  late Map<DateTime, String> _availabilityStatus;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _selectedRange = null;
    _availabilityStatus = {};
    _loadAvailabilityData();
  }

  Future<void> _loadAvailabilityData() async {
    final Map<DateTime, String> statusMap = {};
    
    // Load room availability
    if (widget.room.availabilityFrom != null && widget.room.availabilityTo != null) {
      final start = widget.room.availabilityFrom!;
      final end = widget.room.availabilityTo!;
      
      for (DateTime day = start; day.isBefore(end.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
        final dateKey = DateTime(day.year, day.month, day.day);
        statusMap[dateKey] = 'available';
      }
    }

    // Load existing bookings
    final bookingsQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('roomId', isEqualTo: widget.room.id)
        .where('status', isEqualTo: 'accepted')
        .get();

    for (final doc in bookingsQuery.docs) {
      final from = (doc.data()['from'] as Timestamp).toDate();
      final to = (doc.data()['to'] as Timestamp).toDate();
      
      // Mark accepted bookings as unavailable for students
      for (DateTime day = from; day.isBefore(to.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
        final dateKey = DateTime(day.year, day.month, day.day);
        statusMap[dateKey] = 'unavailable';
      }
    }

    setState(() {
      _availabilityStatus = statusMap;
    });
  }

  String _getEventForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _availabilityStatus[dateKey] ?? 'unavailable';
  }

  Color _getEventColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'booked':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getEventTitle(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'booked':
        return 'Booked';
      case 'pending':
        return 'Pending';
      default:
        return 'Unavailable';
    }
  }

  bool _isDateSelectable(DateTime day) {
    // Only allow selecting dates from today onwards
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dayStart = DateTime(day.year, day.month, day.day);
    
    if (dayStart.isBefore(todayStart)) return false;
    
    // Check if date is within room availability
    if (widget.room.availabilityFrom != null && dayStart.isBefore(widget.room.availabilityFrom!)) {
      return false;
    }
    if (widget.room.availabilityTo != null && dayStart.isAfter(widget.room.availabilityTo!)) {
      return false;
    }
    
    // Check if date is not already booked
    final status = _getEventForDay(day);
    return status == 'available';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          rangeStartDay: _selectedRange?.start,
          rangeEndDay: _selectedRange?.end,
          rangeSelectionMode: widget.isOwner ? RangeSelectionMode.toggledOff : RangeSelectionMode.toggledOn,
          onDaySelected: (selectedDay, focusedDay) {
            if (!widget.isOwner) {
              // For students, handle range selection
              if (_selectedRange == null) {
                setState(() {
                  _selectedRange = DateTimeRange(start: selectedDay, end: selectedDay);
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              } else {
                // Check if the range is valid
                final start = _selectedRange!.start;
                final end = selectedDay;
                
                if (start.isAfter(end)) {
                  setState(() {
                    _selectedRange = DateTimeRange(start: end, end: start);
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                } else {
                  setState(() {
                    _selectedRange = DateTimeRange(start: start, end: end);
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              }
            } else {
              // For owners, just update selected day
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: const TextStyle(color: Colors.red),
            disabledTextStyle: TextStyle(color: Colors.grey[400]),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          enabledDayPredicate: _isDateSelectable,
          eventLoader: (day) {
            final status = _getEventForDay(day);
            return status != 'unavailable' ? [status] : [];
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                final status = events.first as String;
                return Positioned(
                  bottom: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getEventColor(status),
                    ),
                    width: 8,
                    height: 8,
                  ),
                );
              }
              return null;
            },
            selectedBuilder: (context, date, _) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            rangeStartBuilder: (context, date, _) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            rangeEndBuilder: (context, date, _) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            withinRangeBuilder: (context, date, _) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Legend
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Legend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _LegendItem(
                    color: Colors.green,
                    label: 'Available',
                  ),
                  if (widget.isOwner) ...[
                    _LegendItem(
                      color: Colors.blue,
                      label: 'Booked',
                    ),
                    _LegendItem(
                      color: Colors.orange,
                      label: 'Pending',
                    ),
                  ],
                  _LegendItem(
                    color: Colors.grey,
                    label: 'Unavailable',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Selected day/range info
        if (_selectedRange != null && !widget.isOwner) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected Period',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'From: ${_selectedRange!.start.day}/${_selectedRange!.start.month}/${_selectedRange!.start.year}',
                  style: TextStyle(color: Colors.green[700]),
                ),
                Text(
                  'To: ${_selectedRange!.end.day}/${_selectedRange!.end.month}/${_selectedRange!.end.year}',
                  style: TextStyle(color: Colors.green[700]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to booking page or show booking dialog
                      _showBookingDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Book This Period'),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}: ${_getEventTitle(_getEventForDay(_selectedDay))}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Text(
          'Do you want to book this property from ${_selectedRange!.start.day}/${_selectedRange!.start.month}/${_selectedRange!.start.year} to ${_selectedRange!.end.day}/${_selectedRange!.end.month}/${_selectedRange!.end.year}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Here you can implement the actual booking logic
              // For now, just show a success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking request sent!')),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
