import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:unistay/models/room.dart';
import 'package:unistay/models/booking_request.dart';
import 'package:unistay/services/booking_service.dart';

class AvailabilitySummary extends StatefulWidget {
  final Room room;
  final bool isOwner;

  const AvailabilitySummary({
    super.key,
    required this.room,
    required this.isOwner,
  });

  @override
  State<AvailabilitySummary> createState() => _AvailabilitySummaryState();
}

class _AvailabilitySummaryState extends State<AvailabilitySummary> {
  late Map<DateTime, String> _statusByDay; // available | pending | booked | unavailable
  StreamSubscription<List<BookingRequest>>? _sub;

  @override
  void initState() {
    super.initState();
    _statusByDay = {};
    _subscribe();
  }

  void _subscribe() {
    final Map<DateTime, String> base = {};
    for (final range in widget.room.availabilityRanges) {
      for (DateTime d = range.start; d.isBefore(range.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
        base[DateTime(d.year, d.month, d.day)] = 'available';
      }
    }

    final bookingService = BookingService();
    _sub = bookingService.getRequestsForProperty(widget.room.id).listen((reqs) {
      final map = Map<DateTime, String>.from(base);

      String norm(String s) {
        s = s.toLowerCase().trim();
        if (s == 'accepted' || s == 'approved' || s == 'confirmed') return 'accepted';
        if (s == 'pending' || s == 'awaiting' || s == 'waiting') return 'pending';
        if (s == 'rejected' || s == 'declined' || s == 'denied' || s == 'cancelled' || s == 'canceled') return 'rejected';
        return s;
      }

      for (final r in reqs) {
        final st = norm(r.status);
        if (widget.isOwner) {
          if (st == 'accepted') {
            for (DateTime d = r.requestedRange.start; d.isBefore(r.requestedRange.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
              map[DateTime(d.year, d.month, d.day)] = 'booked';
            }
          } else if (st == 'pending') {
            for (DateTime d = r.requestedRange.start; d.isBefore(r.requestedRange.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
              final k = DateTime(d.year, d.month, d.day);
              if (map[k] != 'booked') map[k] = 'pending';
            }
          }
        } else {
          // Student: only accepted blocks availability
          if (st == 'accepted') {
            for (DateTime d = r.requestedRange.start; d.isBefore(r.requestedRange.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
              map[DateTime(d.year, d.month, d.day)] = 'unavailable';
            }
          }
        }
      }

      if (mounted) setState(() => _statusByDay = map);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  List<DateTimeRange> _deriveRangesFor(String status) {
    final dates = _statusByDay.entries
        .where((e) => e.value == status)
        .map((e) => e.key)
        .toList()
      ..sort();

    if (dates.isEmpty) return [];

    final ranges = <DateTimeRange>[];
    DateTime? start;
    DateTime? prev;

    for (final date in dates) {
      if (start == null) {
        start = date;
        prev = date;
      } else if (date.difference(prev!).inDays == 1) {
        prev = date;
      } else {
        ranges.add(DateTimeRange(start: start, end: prev!));
        start = date;
        prev = date;
      }
    }

    if (start != null && prev != null) {
      ranges.add(DateTimeRange(start: start, end: prev));
    }

    return ranges;
  }

  @override
  Widget build(BuildContext context) {
    // Derive compact ranges from status map for display
    final List<DateTimeRange> liveAvailable = _deriveRangesFor('available');
    final hasAny = liveAvailable.isNotEmpty;

    if (!hasAny) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Text(
          'No available dates currently',
          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
      );
    }

    return Container(
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
          Text(
            'Available Periods',
            style: TextStyle(
              color: Colors.green[800],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          ...liveAvailable.take(3).map((range) {
            final start = range.start;
            final end = range.end;
            final isSameMonth = start.month == end.month && start.year == end.year;

            String formatDate(DateTime date) {
              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              return '${date.day} ${months[date.month - 1]}';
            }

            String formatDateWithYear(DateTime date) {
              final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
              return '${date.day} ${months[date.month - 1]} ${date.year}';
            }

            final rangeText = isSameMonth
                ? '${formatDate(start)} - ${formatDate(end)}'
                : '${formatDateWithYear(start)} - ${formatDateWithYear(end)}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                rangeText,
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          if (liveAvailable.length > 3) ...[
            Text(
              '... and ${liveAvailable.length - 3} more periods',
              style: TextStyle(
                color: Colors.green[600],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}