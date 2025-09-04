import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/services/booking_service.dart';
import 'package:unistay/views/edit_room.dart';
import 'package:unistay/widgets/property_detail/index.dart';
import 'package:unistay/widgets/property_detail/availability_summary_widget.dart';
import 'package:unistay/widgets/property_detail/property_rating_widget.dart';
import 'package:unistay/widgets/property_detail/property_reviews_widget.dart';
import 'package:unistay/widgets/property_detail/review_form_widget.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _roomStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _buildLoading();
            final room = Room.fromFirestore(snapshot.data!);
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  PropertyGalleryWidget(
                    photoUrls: room.photoUrls,
                    isTablet: _isTablet,
                  ),
                  _buildContentContainer(room),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
          onPressed: () => _editProperty(),
          icon: const Icon(Icons.edit),
          tooltip: 'Edit Property',
        ),
      ] : null,
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E56CF)),
      ),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _roomStream() {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots();
  }

  bool get _isTablet {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > 600;
  }

  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkOwnerStatus();
  }

  Future<void> _checkOwnerStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (widget.isOwnerView) {
      setState(() {
        _isOwner = true;
      });
      return;
    }
    
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .get();
        
        if (doc.exists) {
          final room = Room.fromFirestore(doc);
          setState(() {
            _isOwner = currentUser.uid == room.ownerUid;
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  void _navigateToMap(Room room) {
    Navigator.of(context).pushNamed(
      '/map',
      arguments: {
        'initialLat': room.lat,
        'initialLng': room.lng,
        'title': room.title,
        'address': room.fullAddress,
      },
    );
  }

  Widget _buildContentContainer(Room room) {
    return Container(
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
          PropertyHeaderWidget(room: room),
          const SizedBox(height: 24),
          WeatherSummaryWidget(room: room),
          const SizedBox(height: 24),
          PropertyFeaturesWidget(room: room),
          const SizedBox(height: 24),
          PropertyDescriptionWidget(description: room.description),
          const SizedBox(height: 24),
          PropertyAmenitiesWidget(amenities: room.amenities),
          const SizedBox(height: 24),
          PropertyAddressWidget(
            room: room,
            onMapTap: () => _navigateToMap(room),
          ),
          const SizedBox(height: 24),
          ConnectionsSectionWidget(room: room),
          const SizedBox(height: 24),
          if (room.availabilityRanges.isNotEmpty)
            AvailabilitySummary(room: room, isOwner: _isOwner),
          const SizedBox(height: 24),
          _buildCalendarSection(room),
          const SizedBox(height: 24),
          PropertyActionsWidget(
            room: room,
            isOwnerView: _isOwner,
            currentUserId: FirebaseAuth.instance.currentUser?.uid,
            selectedRange: _selectedRange,
            onBook: () => _bookProperty(room),
            onEdit: () => _editProperty(),
            onDelete: () => _deleteProperty(room),
          ),
          const SizedBox(height: 24),
          _buildReviewsSection(room),
          const SizedBox(height: 24),
          _buildRatingSection(room),
        ],
      ),
    );
  }



  Widget _buildCalendarSection(Room room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          icon: Icons.calendar_month,
          iconColor: const Color(0xFF6E56CF),
          title: 'Availability Calendar',
        ),
        const SizedBox(height: 12),
        room.availabilityRanges.isEmpty
            ? _buildEmptyCalendar()
            : AvailabilityCalendarWidget(
          room: room,
          isOwner: _isOwner,
          onRangeSelected: (range) {
            setState(() {
              _selectedRange = range;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEmptyCalendar() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return Container(
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
              widget.isOwnerView || (currentUser != null && _isOwner)
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
    );
  }

  Widget _buildRatingSection(Room room) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeaderWidget(
          icon: Icons.star,
          iconColor: const Color(0xFFFFD700),
          title: 'Ratings & Reviews',
        ),
        const SizedBox(height: 12),
        PropertyRatingWidget(propertyId: room.id),
      ],
    );
  }

  Widget _buildReviewsSection(Room room) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userType = _isOwner ? 'owner' : 'student';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing reviews first
        PropertyReviewsWidget(propertyId: room.id),
        const SizedBox(height: 24),
        
        // Review form at the bottom (for all users - validation is handled inside the widget)
        if (currentUser != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: ReviewFormWidget(
              key: ValueKey('review_form_${room.id}_${currentUser.uid}'),
              propertyId: room.id,
              userType: userType,
              onReviewSubmitted: () {
                setState(() {
                  // Refresh the page to show new review
                });
              },
            ),
          ),
        ],

      ],
    );
  }



  void _editProperty() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditRoomPage(roomId: widget.roomId),
      ),
    );
  }

  Future<void> _bookProperty(Room room) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please log in first');
      return;
    }

    if (_selectedRange == null) {
      _showSnackBar('Please select dates from the calendar above');
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
      _showSnackBar('Selected dates are outside availability');
      return;
    }

    try {
      final bookingService = BookingService();

      await bookingService.createBookingRequest(
        propertyId: room.id,
        requestedRange: _selectedRange!,
        ownerUid: room.ownerUid,
        studentName: user.displayName ?? 'Student',
        propertyTitle: room.title,
      );

      _showSnackBar('Booking request sent successfully!');
      setState(() {
        _selectedRange = null;
      });
    } catch (e) {
      _showSnackBar('Booking failed: $e');
    }
  }

  Future<void> _deleteProperty(Room room) async {
    // Check for pending or accepted booking requests
    try {
      final bookingService = BookingService();
      final requests = await bookingService.getRequestsForProperty(room.id).first;

      final hasActiveBookings = requests.any((request) =>
      request.status == 'pending' || request.status == 'accepted');

      if (hasActiveBookings && mounted) {
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

        _showAlertDialog(
          'Cannot Delete Property',
          message,
        );
        return;
      }
    } catch (e) {}

    final confirmed = await _showConfirmDialog(
      'Delete Listing',
      'Are you sure you want to delete this listing? This action cannot be undone.',
    );

    if (confirmed != true) return;

    try {
      // Soft delete - update status to 'deleted'
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(room.id)
          .update({
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Listing deleted');
      }
    } catch (e) {
      _showSnackBar('Delete failed: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _showAlertDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    if (!mounted) return Future.value(false);

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
  }
}