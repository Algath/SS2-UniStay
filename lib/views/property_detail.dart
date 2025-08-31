import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/views/edit_room.dart';
import 'package:table_calendar/table_calendar.dart';

class PropertyDetailPage extends StatelessWidget {
  final String roomId;
  final bool isOwnerView;
  const PropertyDetailPage({
    super.key, 
    required this.roomId,
    this.isOwnerView = false,
  });

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    final currentUser = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Property Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        centerTitle: true,
        actions: isOwnerView ? [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditRoomPage(roomId: roomId),
                ),
              );
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Property',
          ),
        ] : null,
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E56CF)),
                ),
              );
            }
            final room = Room.fromFirestore(snap.data!);
            final img = room.photos.isNotEmpty ? room.photos.first : null;

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Property Image
                  Container(
                    width: double.infinity,
                    height: isTablet ? 300 : 250,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: img == null
                          ? Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.apartment,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                            )
                          : Image.network(
                              img,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.apartment,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Content Container
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description Section (moved to top)
                        if (room.description.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.description,
                                  color: Color(0xFF6E56CF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
              padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE9ECEF)),
                            ),
                            child: Text(
                              room.description,
                              style: const TextStyle(
                                color: Color(0xFF495057),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Title and Price Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room.title,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${room.rooms} rooms • ${room.bathrooms} bathrooms • ${room.type == 'room' ? 'Room' : 'Whole property'}',
                                    style: const TextStyle(
                                      color: Color(0xFF6C757D),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6E56CF).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'CHF',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${room.price}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    '/month',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Property Details Row
                        Row(
                          children: [
                            // Left Column - Address & Availability
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Address Section
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.location_on,
                                          color: Colors.red[600],
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Address',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE9ECEF)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${room.street} ${room.houseNumber}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${room.postcode} ${room.city}',
                                          style: const TextStyle(
                                            color: Color(0xFF6C757D),
                                          ),
                                        ),
                                        Text(
                                          room.country,
                                          style: const TextStyle(
                                            color: Color(0xFF6C757D),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Availability Section
                                  if (room.availabilityFrom != null || room.availabilityTo != null) ...[
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.calendar_today,
                                            color: Colors.green[600],
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Availability',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2C3E50),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green[200]!),
                                      ),
                                      child: Text(
                                        room.availabilityFrom != null && room.availabilityTo != null
                                            ? '${room.availabilityFrom!.toString().split(" ").first} → ${room.availabilityTo!.toString().split(" ").first}'
                                            : room.availabilityFrom != null
                                                ? 'From ${room.availabilityFrom!.toString().split(" ").first}'
                                                : 'Until ${room.availabilityTo!.toString().split(" ").first}',
                                        style: TextStyle(
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            // Right Column - Property Features
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.home,
                                          color: Colors.blue[600],
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Features',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE9ECEF)),
                                    ),
                                    child: Column(
                                      children: [
                                        _FeatureRow(
                                          icon: Icons.square_foot,
                                          label: 'Size',
                                          value: '${room.sizeSqm} m²',
                                        ),
                                        const SizedBox(height: 8),
                                        _FeatureRow(
                                          icon: room.furnished ? Icons.chair : Icons.chair_outlined,
                                          label: 'Furnished',
                                          value: room.furnished ? 'Yes' : 'No',
                                        ),
                                        const SizedBox(height: 8),
                                        _FeatureRow(
                                          icon: room.utilitiesIncluded ? Icons.electric_bolt : Icons.electric_bolt_outlined,
                                          label: 'Charges Included',
                                          value: room.utilitiesIncluded ? 'Yes' : 'No',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Amenities Section
                        if (room.amenities.isNotEmpty) ...[
                          Row(
              children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.orange[600],
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Amenities',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                ),
                const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: room.amenities.map((amenity) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6E56CF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF6E56CF).withOpacity(0.3)),
                              ),
                              child: Text(
                                amenity,
                                style: const TextStyle(
                                  color: Color(0xFF6E56CF),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Calendar Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6E56CF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.calendar_month,
                                color: Color(0xFF6E56CF),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Availability Calendar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                const SizedBox(height: 12),
                        _AvailabilityCalendar(
                          room: room,
                          isOwner: isOwnerView || (currentUser?.uid == room.ownerUid),
                        ),
                        const SizedBox(height: 24),

                        // Action buttons
                        if (isOwnerView) ...[
                          // Owner action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _deleteProperty(context, room),
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  label: const Text('Delete Property'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6E56CF).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => EditRoomPage(roomId: roomId),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit Property'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (currentUser?.uid != room.ownerUid) ...[
                          // Student book button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6E56CF).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => _bookProperty(context, room),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Book This Period',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _bookProperty(BuildContext context, Room room) async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected dates are outside availability')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    }
  }

  Future<void> _deleteProperty(BuildContext context, Room room) async {
    // Check for pending booking requests
    final pendingBookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('roomId', isEqualTo: room.id)
        .where('status', isEqualTo: 'pending')
        .get();

    if (pendingBookings.docs.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This listing has pending booking requests. Please respond to them first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
          'Are you sure you want to delete this listing? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      // Soft delete - update status to 'deleted'
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(room.id)
          .update({
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted')),
        );
                      }
                    } catch (e) {
                      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6C757D),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6C757D),
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
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
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late Map<DateTime, String> _availabilityStatus;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
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
        .get();

    for (final doc in bookingsQuery.docs) {
      final from = (doc.data()['from'] as Timestamp).toDate();
      final to = (doc.data()['to'] as Timestamp).toDate();
      final status = doc.data()['status'] as String;
      
      if (widget.isOwner) {
        // Owner sees all booking statuses
        if (status == 'accepted') {
          for (DateTime day = from; day.isBefore(to.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
            final dateKey = DateTime(day.year, day.month, day.day);
            statusMap[dateKey] = 'booked';
          }
        } else if (status == 'pending') {
          for (DateTime day = from; day.isBefore(to.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
            final dateKey = DateTime(day.year, day.month, day.day);
            if (statusMap[dateKey] == 'available') {
              statusMap[dateKey] = 'pending';
            }
          }
        }
      } else if (status == 'accepted') {
        // Students only see accepted bookings as unavailable
        for (DateTime day = from; day.isBefore(to.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
          final dateKey = DateTime(day.year, day.month, day.day);
          statusMap[dateKey] = 'unavailable';
        }
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
    
    // Check if date is available
    final status = _getEventForDay(day);
    return status == 'available';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        children: [
          Container(
            height: 350,
            padding: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              onDaySelected: (selectedDay, focusedDay) {
                if (!widget.isOwner && _isDateSelectable(selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _rangeStart = selectedDay;
                    _rangeEnd = null;
                  });
                }
              },
              onRangeSelected: (start, end, focusedDay) {
                if (!widget.isOwner) {
                  setState(() {
                    _selectedDay = start ?? _selectedDay;
                    _focusedDay = focusedDay;
                    _rangeStart = start;
                    _rangeEnd = end;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF6E56CF),
                  shape: BoxShape.circle,
                ),
                rangeStartDecoration: BoxDecoration(
                  color: Color(0xFF6E56CF),
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: Color(0xFF6E56CF),
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor: Color(0x336E56CF),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                ),
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
              ),
            ),
          ),
          
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Legend',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6C757D),
          ),
        ),
      ],
    );
  }
}
