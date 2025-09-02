import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/models/booking_request.dart';
import 'package:unistay/services/booking_service.dart';
import 'package:unistay/views/edit_room.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:unistay/services/routing_service.dart';
import 'package:unistay/services/geocoding_service.dart';
import 'package:unistay/services/utils.dart';
// import 'package:unistay/services/transit_service.dart'; 
import 'package:unistay/services/swiss_stops_service.dart';
import 'package:unistay/services/transit_service.dart' show TransitStop;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/services/swiss_transit_service.dart';

class PropertyDetailPage extends StatefulWidget {
  final String roomId;
  final bool isOwnerView;
  const PropertyDetailPage({
    super.key, 
    required this.roomId,
    this.isOwnerView = false,
  });

  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  DateTimeRange? _selectedRange;
  String? _commuteSummary;
  bool _loadingCommute = false;
  List<TransitStop> _stops = [];
  bool _loadingStops = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _bestModeInWindow;
  List<TransitItinerary> _itineraries = [];
  bool _loadingItineraries = false;

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
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
        actions: widget.isOwnerView ? [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditRoomPage(roomId: widget.roomId),
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
            final img = room.photoUrls.isNotEmpty ? room.photoUrls.first : null;
            
            // Debug: Check availability ranges
            print('DEBUG: Room ID: ${room.id}');
            print('DEBUG: Room title: ${room.title}');
            print('DEBUG: Availability ranges count: ${room.availabilityRanges.length}');
            for (int i = 0; i < room.availabilityRanges.length; i++) {
              final range = room.availabilityRanges[i];
              print('DEBUG: Range $i: ${range.start} to ${range.end}');
            }

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
                        // Commute to University
                        _buildCommuteSection(room),
                        const SizedBox(height: 12),
                        _buildTransitSection(room),
                        const SizedBox(height: 12),
                        _buildConnectionsSection(room),
                        const SizedBox(height: 16),
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
                                  if (room.availabilityRanges.isNotEmpty) ...[
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
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          for (var range in room.availabilityRanges) ...[
                                            if (range != room.availabilityRanges.first)
                                              const SizedBox(height: 8),
                                            Text(
                                              '${range.start.toString().split(" ").first} → ${range.end.toString().split(" ").first}',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
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
                        room.availabilityRanges.isEmpty 
                          ? Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE9ECEF)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      widget.isOwnerView || (currentUser?.uid == room.ownerUid)
                                        ? 'No availability ranges set\nEdit property to add availability'
                                        : 'No available dates\nCheck back later',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _AvailabilityCalendar(
                              room: room,
                              isOwner: widget.isOwnerView || (currentUser?.uid == room.ownerUid),
                              onRangeSelected: (range) {
                                setState(() {
                                  _selectedRange = range;
                                });
                              },
                            ),
                        const SizedBox(height: 24),

                        // Action buttons
                        if (widget.isOwnerView) ...[
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
                                          builder: (_) => EditRoomPage(roomId: widget.roomId),
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

    // Check if user has selected dates in the calendar
    if (_selectedRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select dates from the calendar above')),
      );
      return;
    }

    // Validate selected range is within available ranges
    bool isValidRange = false;
    for (var range in room.availabilityRanges) {
      if (_selectedRange!.start.isAfter(range.start.subtract(const Duration(days: 1))) &&
          _selectedRange!.end.isBefore(range.end.add(const Duration(days: 1)))) {
        isValidRange = true;
        break;
      }
    }

    if (!isValidRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected dates are outside availability')),
      );
                      return;
                    }

    try {
      final bookingService = BookingService();
      
      print('DEBUG: Creating booking request...');
      print('DEBUG: Property ID: ${room.id}');
      print('DEBUG: Owner UID: ${room.ownerUid}');
      print('DEBUG: Student UID: ${user.uid}');
      print('DEBUG: Student Name: ${user.displayName}');
      print('DEBUG: Property Title: ${room.title}');
      print('DEBUG: Selected Range: ${_selectedRange!.start} - ${_selectedRange!.end}');
      
      await bookingService.createBookingRequest(
        propertyId: room.id,
        requestedRange: _selectedRange!,
        ownerUid: room.ownerUid,
        studentName: user.displayName ?? 'Student',
        propertyTitle: room.title,
      );
      
      print('DEBUG: Booking request created successfully');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request sent successfully!')),
        );
        // Clear selected range after successful booking
        setState(() {
          _selectedRange = null;
        });
      }
    } catch (e) {
      print('DEBUG: Booking request failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e')),
        );
      }
    }
  }

  Widget _buildCommuteSection(Room room) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
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
                child: Icon(Icons.directions, color: Colors.blue[600], size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Commute to University',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _loadingCommute ? null : () => _computeCommute(room),
                child: _loadingCommute
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Calculate'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Sabah saat aralığı seçici (Wrap ile, taşmaya dayanıklı)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildTimePicker('From', _startTime, (t) => setState(() => _startTime = t)),
              _buildTimePicker('To', _endTime, (t) => setState(() => _endTime = t)),
              TextButton(
                onPressed: () => _computeBestModeInWindow(room),
                child: const Text('Best in window'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_commuteSummary == null)
            const Text(
              'Get walking / cycling / driving times from this property to your university.',
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 13),
            )
          else
            Text(
              _commuteSummary!,
              style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w600),
            ),
          if (_bestModeInWindow != null) ...[
            const SizedBox(height: 6),
            Text(
              'Fastest between ${_fmtTod(_startTime)}-${_fmtTod(_endTime)}: $_bestModeInWindow',
              style: const TextStyle(color: Color(0xFF2C3E50)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay value, void Function(TimeOfDay) onChanged) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showTimePicker(context: context, initialTime: value);
        if (picked != null) onChanged(picked);
      },
      icon: const Icon(Icons.schedule, size: 16),
      label: Text('$label ${_fmtTod(value)}'),
    );
  }

  Future<void> _computeCommute(Room room) async {
    setState(() => _loadingCommute = true);
    try {
      // 1) Öğrencinin profiline göre üniversite adresini al ve geocode et; yoksa Sion'a düş
      double uLat = hesSoValaisLat;
      double uLng = hesSoValaisLng;
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          final m = doc.data() ?? {};
          final uniAddress = (m['uniAddress'] ?? '').toString();
          if (uniAddress.isNotEmpty) {
            final geo = GeocodingService();
            final pos = await geo.resolve(uniAddress);
            if (pos.$1 != 0.0 || pos.$2 != 0.0) {
              uLat = pos.$1;
              uLng = pos.$2;
            }
          }
        }
      } catch (_) {}
      final r = RoutingService();
      final w = await r.routeDuration(
        fromLat: room.lat,
        fromLng: room.lng,
        toLat: uLat,
        toLng: uLng,
        mode: TravelMode.walking,
      );
      final c = await r.routeDuration(
        fromLat: room.lat,
        fromLng: room.lng,
        toLat: uLat,
        toLng: uLng,
        mode: TravelMode.cycling,
      );
      final d = await r.routeDuration(
        fromLat: room.lat,
        fromLng: room.lng,
        toLat: uLat,
        toLng: uLng,
        mode: TravelMode.driving,
      );

      String fmt(Duration? x) => x == null ? '-' : '${x.inMinutes} min';
      final summary = 'Walking: ${fmt(w)} • Cycling: ${fmt(c)} • Driving: ${fmt(d)}';
      setState(() => _commuteSummary = summary);
    } finally {
      if (mounted) setState(() => _loadingCommute = false);
    }
  }

  Future<void> _computeBestModeInWindow(Room room) async {
    // Basit strateji: pencere içinde 30'ar dakikalık örnekleme ve üç mod + Swiss transit karşılaştırması
    setState(() => _bestModeInWindow = null);
    // Resolve university coords again
    double uLat = hesSoValaisLat;
    double uLng = hesSoValaisLng;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final m = doc.data() ?? {};
        final uniAddress = (m['uniAddress'] ?? '').toString();
        if (uniAddress.isNotEmpty) {
          final geo = GeocodingService();
          final pos = await geo.resolve(uniAddress);
          if (pos.$1 != 0.0 || pos.$2 != 0.0) {
            uLat = pos.$1;
            uLng = pos.$2;
          }
        }
      }
    } catch (_) {}

    final r = RoutingService();
    final s = SwissTransitService();

    DateTime now = DateTime.now();
    DateTime windowStart = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
    DateTime windowEnd = DateTime(now.year, now.month, now.day, _endTime.hour, _endTime.minute);
    if (windowEnd.isBefore(windowStart)) {
      windowEnd = windowStart.add(const Duration(hours: 1));
    }

    final samples = <DateTime>[];
    for (DateTime t = windowStart; !t.isAfter(windowEnd); t = t.add(const Duration(minutes: 30))) {
      samples.add(t);
    }

    Duration? best;
    String bestLabel = '';

    Future<void> consider(String label, Duration? d) async {
      if (d == null) return;
      if (best == null || d < best!) {
        best = d;
        bestLabel = label;
      }
    }

    for (final t in samples) {
      final w = await r.routeDuration(fromLat: room.lat, fromLng: room.lng, toLat: uLat, toLng: uLng, mode: TravelMode.walking);
      await consider('Walking (${w?.inMinutes} min)', w);
      final c = await r.routeDuration(fromLat: room.lat, fromLng: room.lng, toLat: uLat, toLng: uLng, mode: TravelMode.cycling);
      await consider('Cycling (${c?.inMinutes} min)', c);
      final d = await r.routeDuration(fromLat: room.lat, fromLng: room.lng, toLat: uLat, toLng: uLng, mode: TravelMode.driving);
      await consider('Driving (${d?.inMinutes} min)', d);
      final pt = await s.connectionDuration(fromLat: room.lat, fromLng: room.lng, toLat: uLat, toLng: uLng, departureDateTime: t);
      await consider('Transit (${pt?.inMinutes} min)', pt);
    }

    if (mounted) setState(() => _bestModeInWindow = bestLabel.isEmpty ? null : bestLabel);
  }

  String _fmtTod(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _buildTransitSection(Room room) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.directions_bus, color: Colors.orange[700], size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Nearby Public Transport',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _loadingStops ? null : () => _loadNearbyStops(room),
                child: _loadingStops
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Find Stops'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_stops.isEmpty)
            const Text(
              'Find the closest bus/train/tram stops and walking time from the property.',
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 13),
            )
          else
            Column(
              children: _stops.take(5).map((s) {
                final walkMins = walkingMinsFromKm(s.distanceKm);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.place, color: Colors.orange[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${s.name} • ${s.type}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('${walkMins} min walk', style: const TextStyle(color: Color(0xFF6C757D))),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _loadNearbyStops(Room room) async {
    setState(() => _loadingStops = true);
    try {
      // Only use Swiss official stops API (OGC API – Features)
      final swiss = SwissStopsService();
      final res = await swiss.fetchNearbyStops(lat: room.lat, lng: room.lng);
      setState(() => _stops = res);
    } finally {
      if (mounted) setState(() => _loadingStops = false);
    }
  }

  Widget _buildConnectionsSection(Room room) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.alt_route, color: Colors.purple[700], size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'Public Transport Connections',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _loadingItineraries ? null : () => _loadConnections(room),
                child: _loadingItineraries
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Find Connections'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_itineraries.isEmpty)
            const Text(
              'See possible bus/train (multi-leg) connections to your university.',
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 13),
            )
          else
            Column(
              children: _itineraries.take(3).map((it) => _buildItineraryCard(it)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildItineraryCard(TransitItinerary it) {
    String two(int n) => n.toString().padLeft(2, '0');
    String fmt(DateTime d) => '${two(d.hour)}:${two(d.minute)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.purple[700]),
              const SizedBox(width: 6),
              Text('${fmt(it.departure)} → ${fmt(it.arrival)} • ${it.duration.inMinutes} min',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ...it.legs.map((l) => Row(
            children: [
              Icon(_legIcon(l.type), size: 16, color: Colors.purple[700]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${l.type.toUpperCase()} ${l.line ?? ''}  ${l.fromName} → ${l.toName}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${fmt(l.departure)}-${fmt(l.arrival)}', style: const TextStyle(color: Color(0xFF6C757D))),
            ],
          )),
        ],
      ),
    );
  }

  IconData _legIcon(String type) {
    switch (type) {
      case 'walk':
        return Icons.directions_walk;
      case 'bus':
        return Icons.directions_bus;
      case 'tram':
        return Icons.tram;
      case 'ship':
        return Icons.directions_boat;
      default:
        return Icons.train;
    }
  }

  Future<void> _loadConnections(Room room) async {
    setState(() => _loadingItineraries = true);
    try {
      double uLat = hesSoValaisLat;
      double uLng = hesSoValaisLng;
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          final m = doc.data() ?? {};
          final uniAddress = (m['uniAddress'] ?? '').toString();
          if (uniAddress.isNotEmpty) {
            final geo = GeocodingService();
            final pos = await geo.resolve(uniAddress);
            if (pos.$1 != 0.0 || pos.$2 != 0.0) {
              uLat = pos.$1;
              uLng = pos.$2;
            }
          }
        }
      } catch (_) {}

      final svc = SwissTransitService();
      final now = DateTime.now();
      final dep = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);
      final res = await svc.connections(
        fromLat: room.lat,
        fromLng: room.lng,
        toLat: uLat,
        toLng: uLng,
        departureDateTime: dep,
        limit: 5,
      );
      setState(() => _itineraries = res);
    } finally {
      if (mounted) setState(() => _loadingItineraries = false);
    }
  }

  Future<void> _deleteProperty(BuildContext context, Room room) async {
    // Check for pending or accepted booking requests
    try {
      final bookingService = BookingService();
      final requests = await bookingService.getRequestsForProperty(room.id).first;
      
      final hasActiveBookings = requests.any((request) => 
        request.status == 'pending' || request.status == 'accepted');
      
      if (hasActiveBookings && context.mounted) {
        final pendingCount = requests.where((r) => r.status == 'pending').length;
        final acceptedCount = requests.where((r) => r.status == 'accepted').length;
        
        String message = 'This property cannot be deleted because it has ';
        if (pendingCount > 0 && acceptedCount > 0) {
          message += '$pendingCount pending and $acceptedCount accepted booking requests.';
        } else if (pendingCount > 0) {
          message += '$pendingCount pending booking requests. Please respond to them first.';
        } else {
          message += '$acceptedCount accepted bookings.';
        }
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cannot Delete Property'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    } catch (e) {
      print('Error checking bookings: $e');
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
  final Function(DateTimeRange?)? onRangeSelected;
  
  const _AvailabilityCalendar({
    required this.room,
    required this.isOwner,
    this.onRangeSelected,
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
  StreamSubscription<List<BookingRequest>>? _requestsSub;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _availabilityStatus = {};
    _subscribeAvailability();
  }

  void _subscribeAvailability() {
    final Map<DateTime, String> baseMap = {};
    // Base: room availability → available
    for (var range in widget.room.availabilityRanges) {
      for (DateTime day = range.start; day.isBefore(range.end.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
        final dateKey = DateTime(day.year, day.month, day.day);
        baseMap[dateKey] = 'available';
      }
    }

    final bookingService = BookingService();
    _requestsSub = bookingService.getRequestsForProperty(widget.room.id).listen((requests) {
      final Map<DateTime, String> statusMap = Map.of(baseMap);

      String normalize(String raw) {
        final s = (raw).toLowerCase().trim();
        if (s == 'accepted' || s == 'approved' || s == 'confirmed') return 'accepted';
        if (s == 'pending' || s == 'awaiting' || s == 'waiting') return 'pending';
        if (s == 'rejected' || s == 'declined' || s == 'denied' || s == 'cancelled' || s == 'canceled') return 'rejected';
        return s;
      }

      for (final request in requests) {
        final st = normalize(request.status);
        if (widget.isOwner) {
          // Owner tüm durumları görür: accepted → booked, pending → pending (availability olmasa bile göster)
          if (st == 'accepted') {
            for (DateTime day = request.requestedRange.start; day.isBefore(request.requestedRange.end.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
              final dateKey = DateTime(day.year, day.month, day.day);
              statusMap[dateKey] = 'booked';
            }
          } else if (st == 'pending') {
            for (DateTime day = request.requestedRange.start; day.isBefore(request.requestedRange.end.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
              final dateKey = DateTime(day.year, day.month, day.day);
              // Pending, available değilse bile turuncu göster
              // Booked (accepted) her zaman önceliklidir, o yüzden booked üzerine yazmayalım
              if (statusMap[dateKey] != 'booked') {
                statusMap[dateKey] = 'pending';
              }
            }
          }
          // rejected → herhangi bir işaretleme yok, base availability'a geri döner
        } else {
          // Öğrenci: accepted/pending → unavailable
          if (st == 'accepted' || st == 'pending') {
            for (DateTime day = request.requestedRange.start; day.isBefore(request.requestedRange.end.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
              final dateKey = DateTime(day.year, day.month, day.day);
              statusMap[dateKey] = 'unavailable';
            }
          }
        }
      }

      setState(() {
        _availabilityStatus = statusMap;
      });
    }, onError: (e) {
      // Hata durumunda en azından base availability göster
      setState(() {
        _availabilityStatus = Map.of(baseMap);
      });
    });
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    super.dispose();
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
        return Colors.blue; // Owner sees booked as blue
      case 'pending':
        return Colors.orange; // Owner sees pending as orange
      default:
        return Colors.grey; // All unavailable dates are grey
    }
  }

  bool _isDateSelectable(DateTime day) {
    // Only allow selecting dates from today onwards
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dayStart = DateTime(day.year, day.month, day.day);
    
    if (dayStart.isBefore(todayStart)) return false;
    
    // Check if date is within any availability range
    bool isInRange = false;
    for (var range in widget.room.availabilityRanges) {
      if (dayStart.isAfter(range.start.subtract(const Duration(days: 1))) &&
          dayStart.isBefore(range.end.add(const Duration(days: 1)))) {
        isInRange = true;
        break;
      }
    }
    
    if (!isInRange) return false;
    
    // Check if date is available
    final status = _getEventForDay(day);
    return status == 'available';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        children: [
          Container(
            height: isTablet ? 450 : 400,
            padding: const EdgeInsets.all(12),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              rowHeight: 35,
              daysOfWeekHeight: 30,
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
                  
                  // Notify parent widget about range selection
                  if (start != null && end != null) {
                    widget.onRangeSelected?.call(DateTimeRange(start: start, end: end));
                  } else {
                    widget.onRangeSelected?.call(null);
                  }
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red, fontSize: 13),
                defaultTextStyle: TextStyle(fontSize: 13),
                selectedTextStyle: TextStyle(fontSize: 13),
                todayTextStyle: TextStyle(fontSize: 13),
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
                cellMargin: EdgeInsets.all(2),
                cellPadding: EdgeInsets.all(0),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                headerPadding: EdgeInsets.symmetric(vertical: 8),
                titleTextStyle: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                leftChevronPadding: EdgeInsets.all(4),
                rightChevronPadding: EdgeInsets.all(4),
              ),
              enabledDayPredicate: widget.isOwner ? ((_) => true) : _isDateSelectable,
              eventLoader: (day) {
                final status = _getEventForDay(day);
                // Show markers for all statuses except default unavailable
                return status != 'unavailable' ? [status] : [];
              },
              calendarBuilders: CalendarBuilders(
                disabledBuilder: (context, day, focusedDay) {
                  if (widget.isOwner) {
                    final status = _getEventForDay(day);
                    Color? bg;
                    if (status == 'available') {
                      bg = Colors.green[50];
                    } else if (status == 'pending') {
                      bg = Colors.orange[50];
                    } else if (status == 'booked') {
                      bg = Colors.blue[50];
                    } else {
                      bg = Colors.grey[100];
                    }
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }
                  return null;
                },
                todayBuilder: (context, day, focusedDay) {
                  if (widget.isOwner) {
                    final status = _getEventForDay(day);
                    Color? bg;
                    if (status == 'available') {
                      bg = Colors.green[50];
                    } else if (status == 'pending') {
                      bg = Colors.orange[50];
                    } else if (status == 'booked') {
                      bg = Colors.blue[50];
                    } else {
                      bg = Colors.grey[100];
                    }
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border.all(color: const Color(0xFF6E56CF), width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }
                  return null;
                },
                selectedBuilder: (context, day, focusedDay) {
                  if (widget.isOwner) {
                    final status = _getEventForDay(day);
                    Color? bg;
                    if (status == 'available') {
                      bg = Colors.green[50];
                    } else if (status == 'pending') {
                      bg = Colors.orange[50];
                    } else if (status == 'booked') {
                      bg = Colors.blue[50];
                    } else {
                      bg = Colors.grey[100];
                    }
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bg,
                        border: Border.all(color: const Color(0xFF6E56CF), width: 1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }
                  return null;
                },
                defaultBuilder: (context, day, focusedDay) {
                  // Owner görünümünde hücre arka planını duruma göre renklendir
                  if (widget.isOwner) {
                    final status = _getEventForDay(day);
                    Color? bg;
                    if (status == 'available') {
                      bg = Colors.green[50];
                    } else if (status == 'pending') {
                      bg = Colors.orange[50];
                    } else if (status == 'booked') {
                      bg = Colors.blue[50];
                    } else {
                      bg = Colors.grey[100];
                    }
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }
                  return null;
                },
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
