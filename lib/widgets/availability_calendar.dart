import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';
import 'package:unistay/services/booking_service.dart';
import 'package:unistay/models/booking_request.dart';

class AvailabilityCalendar extends StatefulWidget {
  final Function(List<DateTimeRange>) onRangesSelected;
  final List<DateTimeRange> initialRanges;
  // Opsiyonel: Owner görünümünde pending/booked renkleri göstermek için propertyId ve isOwner
  final String? propertyId;
  final bool isOwner;

  const AvailabilityCalendar({
    super.key,
    required this.onRangesSelected,
    this.initialRanges = const [],
    this.propertyId,
    this.isOwner = false,
  });

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  late DateTime _focusedDay;
  DateTimeRange? _selectedRange;
  List<DateTimeRange> _availabilityRanges = [];
  Map<DateTime, String> _statusByDay = {}; // available | pending | booked | unavailable
  StreamSubscription<List<BookingRequest>>? _requestsSub;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedRange = null;
    _availabilityRanges = List.from(widget.initialRanges);
    _initStatusSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    _buildCalendar(),
                    _buildSelectedRangeInfo(),
                    _buildSavedRanges(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Color(0xFF2C3E50)),
          const SizedBox(width: 12),
          const Text(
            'Select Availability Ranges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const Spacer(),
          if (_selectedRange != null) ...[
            TextButton(
              onPressed: _clearSelection,
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _addRange,
              child: const Text('Add Range'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar<String>(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        rangeStartDay: _selectedRange?.start,
        rangeEndDay: _selectedRange?.end,
        rangeSelectionMode: RangeSelectionMode.toggledOn,
        eventLoader: (day) {
          final status = _getStatusForDay(day);
          return status != 'unavailable' ? [status] : [];
        },
        rowHeight: 40,
        daysOfWeekHeight: 35,
        onDaySelected: _onDaySelected,
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Colors.red),
          rangeHighlightColor: Colors.blue.withOpacity(0.3),
          rangeStartDecoration: BoxDecoration(
            color: Colors.blue[600],
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: BoxDecoration(
            color: Colors.blue[600],
            shape: BoxShape.circle,
          ),
          withinRangeDecoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.rectangle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.green[600],
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            if (!widget.isOwner) return null;
            final status = _getStatusForDay(day);
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
              child: Text('${day.day}'),
            );
          },
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              final status = events.first as String;
              return Positioned(
                bottom: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _eventColor(status),
                  ),
                ),
              );
            }
            return null;
          },
        ),
      );
  }

  String _getStatusForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _statusByDay[key] ?? 'unavailable';
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_selectedRange == null) {
      setState(() {
        _selectedRange = DateTimeRange(start: selectedDay, end: selectedDay);
        _focusedDay = focusedDay;
      });
    } else {
      final start = _selectedRange!.start;
      final end = selectedDay;

      if (start.isAfter(end)) {
        setState(() {
          _selectedRange = DateTimeRange(start: end, end: start);
          _focusedDay = focusedDay;
        });
      } else {
        setState(() {
          _selectedRange = DateTimeRange(start: start, end: end);
          _focusedDay = focusedDay;
        });
      }
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedRange = null;
    });
  }

  void _addRange() {
    if (_selectedRange != null) {
      setState(() {
        _availabilityRanges.add(_selectedRange!);
        _selectedRange = null;
        _rebuildBaseStatus();
      });
      widget.onRangesSelected(_availabilityRanges);
    }
  }

  void _removeRange(int index) {
    setState(() {
      _availabilityRanges.removeAt(index);
      _rebuildBaseStatus();
    });
    widget.onRangesSelected(_availabilityRanges);
  }

  String _formatDateRange(DateTimeRange range) {
    return '${range.start.day}/${range.start.month}/${range.start.year} → ${range.end.day}/${range.end.month}/${range.end.year}';
  }

  void _initStatusSubscription() {
    // Önce base: availabilityRanges -> available
    _rebuildBaseStatus();

    // Opsiyonel: propertyId sağlanmışsa rezervasyon akışına bağlan
    if (widget.propertyId != null) {
      final bookingService = BookingService();
      _requestsSub = bookingService.getRequestsForProperty(widget.propertyId!).listen((requests) {
        final Map<DateTime, String> map = Map.of(_statusByDay);

        String normalize(String raw) {
          final s = raw.toLowerCase().trim();
          if (s == 'accepted' || s == 'approved' || s == 'confirmed') return 'accepted';
          if (s == 'pending' || s == 'awaiting' || s == 'waiting') return 'pending';
          if (s == 'rejected' || s == 'declined' || s == 'denied' || s == 'cancelled' || s == 'canceled') return 'rejected';
          return s;
        }

        // Üzerine pending/booked yaz
        for (final req in requests) {
          final st = normalize(req.status);
          if (widget.isOwner) {
            if (st == 'accepted') {
              for (DateTime d = req.requestedRange.start; d.isBefore(req.requestedRange.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
                final k = DateTime(d.year, d.month, d.day);
                map[k] = 'booked';
              }
            } else if (st == 'pending') {
              for (DateTime d = req.requestedRange.start; d.isBefore(req.requestedRange.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
                final k = DateTime(d.year, d.month, d.day);
                if (map[k] != 'booked') map[k] = 'pending';
              }
            }
          } else {
            if (st == 'accepted' || st == 'pending') {
              for (DateTime d = req.requestedRange.start; d.isBefore(req.requestedRange.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
                final k = DateTime(d.year, d.month, d.day);
                map[k] = 'unavailable';
              }
            }
          }
        }

        setState(() {
          _statusByDay = map;
        });
      });
    }
  }

  void _rebuildBaseStatus() {
    final Map<DateTime, String> base = {};
    for (final range in _availabilityRanges) {
      for (DateTime d = range.start; d.isBefore(range.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
        base[DateTime(d.year, d.month, d.day)] = 'available';
      }
    }
    setState(() {
      _statusByDay = base;
    });
  }

  Color _eventColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'booked':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    super.dispose();
  }

  Widget _buildSelectedRangeInfo() {
    if (_selectedRange == null) return const SizedBox.shrink();

    return Container(
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
              'Selected: ${_formatDateRange(_selectedRange!)}',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRanges() {
    if (_availabilityRanges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border(top: BorderSide(color: Colors.grey[300]!)),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[600], size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No availability ranges added yet. Please select dates when your property will be available.',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 20),
              const SizedBox(width: 12),
              Text(
                'Availability Ranges (${_availabilityRanges.length})',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(_availabilityRanges.length, (index) {
            final range = _availabilityRanges[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: Colors.green[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateRange(range),
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _removeRange(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.red[600],
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}