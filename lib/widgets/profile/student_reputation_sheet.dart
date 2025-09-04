import 'package:flutter/material.dart';
import 'package:unistay/services/review_service.dart';
import 'package:unistay/models/student_review.dart';

class StudentReputationSheet extends StatelessWidget {
  final String studentId;
  final String? studentName;

  const StudentReputationSheet({super.key, required this.studentId, this.studentName});

  @override
  Widget build(BuildContext context) {
    final reviewService = ReviewService();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline, color: Color(0xFF2C3E50)),
                const SizedBox(width: 8),
                Text(
                  studentName ?? 'Student',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<Map<String, dynamic>>(
              stream: reviewService.getStudentRatingSummary(studentId),
              builder: (context, snap) {
                final avg = (snap.data?['average'] ?? 0.0) as double;
                final cnt = (snap.data?['count'] ?? 0) as int;
                return Row(
                  children: [
                    _Stars(rating: avg),
                    const SizedBox(width: 8),
                    Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('($cnt reviews)', style: TextStyle(color: Colors.grey[600])),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Flexible(
              child: StreamBuilder<List<StudentReview>>(
                stream: reviewService.getStudentReviews(studentId),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ));
                  }
                  final reviews = snap.data!;
                  if (reviews.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('No reviews yet', style: TextStyle(color: Colors.grey[600])),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = reviews[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _Stars(rating: r.rating, size: 16),
                        title: Text(r.ownerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(r.comment),
                        trailing: Text(
                          _formatDate(r.createdAt),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _Stars extends StatelessWidget {
  final double rating;
  final double size;
  const _Stars({required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final idx = i + 1;
        return Icon(
          rating >= idx
              ? Icons.star
              : (rating >= (idx - 0.5) ? Icons.star_half : Icons.star_border),
          size: size,
          color: const Color(0xFFFFD700),
        );
      }),
    );
  }
}


