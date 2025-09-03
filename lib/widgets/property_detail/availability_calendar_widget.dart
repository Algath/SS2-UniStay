import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:unistay/models/room.dart';
import 'package:unistay/models/booking_request.dart';
import 'package:unistay/services/booking_service.dart';

class AvailabilityCalendarWidget extends StatefulWidget {
  final Room room;
  final bool isOwner;
  final Function(DateTimeRange?)? onRangeSelected;

  const AvailabilityCalendarWidget({
    super.key,
    required this.room,
    required this.isOwner,
    this.onRangeSelected,
  });

  @override
  State<AvailabilityCalendarWidget> createState() => _AvailabilityCalendarWidgetState();
}

class _AvailabilityCalendarWidgetState extends State<AvailabilityCalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTimeRange? _selectedRange;
  late Map<DateTime, String> _statusByDay;
  StreamSubscription<List<BookingRequest>>? _sub;

  @override
  void initState() {
    super.initState();
    _statusByDay = {};
    _subscribe();
  }

  void _subscribe() {
    final Map<DateTime, String> base = {};
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    for (final range in widget.room.availabilityRanges) {
      for (DateTime d = range.start; d.isBefore(range.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
        final key = DateTime(d.year, d.month, d.day);
        if (key.isBefore(todayKey)) {
          base[key] = 'unavailable';
        } else {
          base[key] = 'available';
        }
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
              final k = DateTime(d.year, d.month, d.day);
              if (k.isBefore(todayKey)) {
                map[k] = 'unavailable';
              } else {
                map[k] = 'booked';
              }
            }
          } else if (st == 'pending') {
            for (DateTime d = r.requestedRange.start; d.isBefore(r.requestedRange.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
              final k = DateTime(d.year, d.month, d.day);
              if (k.isBefore(todayKey)) {
                map[k] = 'unavailable';
              } else if (map[k] != 'booked') {
                map[k] = 'pending';
              }
            }
          }
        } else {
          // Student: only accepted blocks availability
          if (st == 'accepted') {
            for (DateTime d = r.requestedRange.start; d.isBefore(r.requestedRange.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
              final k = DateTime(d.year, d.month, d.day);
              map[k] = 'unavailable';
            }
          }
        }
      }
      
      // Mark unavailable for dates not in availability ranges (future window only)
      final endDate = todayKey.add(const Duration(days: 365));
      for (DateTime d = todayKey; d.isBefore(endDate); d = d.add(const Duration(days: 1))) {
        final key = DateTime(d.year, d.month, d.day);
        if (!base.containsKey(key)) {
          map[key] = 'unavailable';
        }
      }

      // Ensure all past days are unavailable
      final pastLimit = todayKey.subtract(const Duration(days: 3650));
      for (DateTime d = pastLimit; d.isBefore(todayKey); d = d.add(const Duration(days: 1))) {
        final key = DateTime(d.year, d.month, d.day);
        map[key] = 'unavailable';
      }

      if (mounted) setState(() => _statusByDay = map);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  bool _isDaySelectable(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final status = _statusByDay[key];
    return status == 'available';
  }

  Color _getDayColor(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final status = _statusByDay[key];

    switch (status) {
      case 'available':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'booked':
        return Colors.red;
      case 'unavailable':
        return Colors.grey;
      default:
        return Colors.transparent;
    }
  }

  String _getDayStatusText(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    final status = _statusByDay[key];

    switch (status) {
      case 'available':
        return 'Available';
      case 'pending':
        return widget.isOwner ? 'Pending Request' : 'Available';
      case 'booked':
        return widget.isOwner ? 'Booked' : 'Unavailable';
      case 'unavailable':
        return 'Unavailable';
      default:
        return 'Not Available';
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!_isDaySelectable(selectedDay)) return;

    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // Range selection logic for non-owners (students)
    if (!widget.isOwner) {
      if (_selectedRange == null) {
        _selectedRange = DateTimeRange(start: selectedDay, end: selectedDay);
      } else {
        final currentStart = _selectedRange!.start;
        final currentEnd = _selectedRange!.end;

        if (selectedDay.isBefore(currentStart)) {
          _selectedRange = DateTimeRange(start: selectedDay, end: currentEnd);
        } else if (selectedDay.isAfter(currentEnd)) {
          _selectedRange = DateTimeRange(start: currentStart, end: selectedDay);
        } else {
          _selectedRange = DateTimeRange(start: selectedDay, end: selectedDay);
        }
      }

      if (widget.onRangeSelected != null) {
        widget.onRangeSelected!(_selectedRange);
      }
    }
  }

  bool _isInSelectedRange(DateTime day) {
    if (_selectedRange == null) return false;
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final start = DateTime(_selectedRange!.start.year, _selectedRange!.start.month, _selectedRange!.start.day);
    final end = DateTime(_selectedRange!.end.year, _selectedRange!.end.month, _selectedRange!.end.day);
    return normalizedDay.isAtSameMomentAs(start) || 
           normalizedDay.isAtSameMomentAs(end) ||
           (normalizedDay.isAfter(start) && normalizedDay.isBefore(end));
  }

  Widget _buildCalendarLegend() {
    final items = <Widget>[];

    void addLegendItem(Color color, String label) {
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6C757D)),
          ),
        ],
      ));
    }

    addLegendItem(Colors.green, 'Available');

    if (widget.isOwner) {
      addLegendItem(Colors.orange, 'Pending');
      addLegendItem(Colors.red, 'Booked');
      addLegendItem(Colors.grey, 'Unavailable');
    } else {
      addLegendItem(Colors.grey, 'Unavailable');
    }

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items,
    );
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: TableCalendar<String>(
              firstDay: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: (day) {
                final status = _statusByDay[DateTime(day.year, day.month, day.day)];
                return status != null ? [status] : [];
              },
              enabledDayPredicate: (day) {
                final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                final key = DateTime(day.year, day.month, day.day);
                return !key.isBefore(today);
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                markersMaxCount: 1,
                markerDecoration: const BoxDecoration(),
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFF6E56CF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                todayDecoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                markersAlignment: Alignment.center,
                markerMargin: const EdgeInsets.all(0),
                cellMargin: const EdgeInsets.all(2),
                cellPadding: EdgeInsets.zero,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Color(0xFF6E56CF),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                headerPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = focusedDay);
              },
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    final color = _getDayColor(date);
                    if (color == Colors.transparent) return null;

                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return null;
                },
                defaultBuilder: (context, date, _) {
                  final isInRange = _isInSelectedRange(date);
                  final color = _getDayColor(date);

                  if (isInRange && !widget.isOwner) {
                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E56CF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF6E56CF).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(
                            color: Color(0xFF6E56CF),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }

                  if (color != Colors.transparent) {
                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withOpacity(0.3), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }

                  return null;
                },
              ),
            ),
          ),

          // Legend
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCalendarLegend(),
                if (!widget.isOwner && _selectedRange != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6E56CF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6E56CF).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Selected: ${_formatDateRange(_selectedRange!)}',
                      style: const TextStyle(
                        color: Color(0xFF6E56CF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                if (_selectedDay != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Selected day: ${_getDayStatusText(_selectedDay!)}',
                    style: TextStyle(
                      color: _getDayColor(_selectedDay!),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(DateTimeRange range) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final start = range.start;
    final end = range.end;

    if (start.year == end.year && start.month == end.month) {
      return '${start.day}-${end.day} ${months[start.month - 1]} ${start.year}';
    } else if (start.year == end.year) {
      return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${start.year}';
    } else {
      return '${start.day} ${months[start.month - 1]} ${start.year} - ${end.day} ${months[end.month - 1]} ${end.year}';
    }
  }
}