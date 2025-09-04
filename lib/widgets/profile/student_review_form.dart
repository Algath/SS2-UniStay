import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unistay/services/review_service.dart';
import 'package:unistay/models/student_review.dart';

class StudentReviewForm extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentReviewForm({super.key, required this.studentId, required this.studentName});

  @override
  State<StudentReviewForm> createState() => _StudentReviewFormState();
}

class _StudentReviewFormState extends State<StudentReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  double _rating = 0.0;
  bool _isSubmitting = false;
  StudentReview? _existing;
  final _service = ReviewService();

  @override
  void initState() {
    super.initState();
    _prefillIfExists();
  }

  Future<void> _prefillIfExists() async {
    final owner = FirebaseAuth.instance.currentUser;
    if (owner == null) return;
    final r = await _service.getOwnerReviewForStudent(ownerId: owner.uid, studentId: widget.studentId);
    if (r != null && mounted) {
      setState(() {
        _existing = r;
        _rating = r.rating;
        _commentController.text = r.comment;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF2C3E50)),
                const SizedBox(width: 8),
                Text('Rate ${widget.studentName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            _buildStars(),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              maxLines: 4,
              maxLength: 500,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              enableInteractiveSelection: true,
              autocorrect: true,
              enableSuggestions: false,
              autofillHints: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Your Review *',
                hintText: 'Share your experience with this student...',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6E56CF), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Color(0xFFF8F9FA),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please write a review';
                }
                if (value.trim().length < 10) {
                  return 'Review must be at least 10 characters';
                }
                return null;
              },
              onTap: () {
                if (!_commentFocusNode.hasFocus) {
                  _commentFocusNode.requestFocus();
                }
              },
              // Keep focus natural while typing; no extra forcing here
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_existing != null ? 'Update Review' : 'Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1.0;
        final filled = _rating >= idx;
        final half = _rating >= (idx - 0.5) && _rating < idx;
        return IconButton(
          icon: Icon(filled ? Icons.star : (half ? Icons.star_half : Icons.star_border), color: const Color(0xFFFFD700)),
          onPressed: () => setState(() => _rating = idx),
        );
      }),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }
    final owner = FirebaseAuth.instance.currentUser;
    if (owner == null) return;

    setState(() => _isSubmitting = true);
    try {
      final review = StudentReview(
        id: _existing?.id ?? '',
        studentId: widget.studentId,
        ownerId: owner.uid,
        ownerName: owner.displayName ?? 'Owner',
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: _existing?.createdAt ?? DateTime.now(),
        updatedAt: _existing != null ? DateTime.now() : null,
      );
      if (_existing == null) {
        await _service.addStudentReview(review);
      } else {
        await _service.updateStudentReview(review);
      }
      if (mounted) {
        // Clear form and hide keyboard before closing the sheet
        FocusScope.of(context).unfocus();
        setState(() {
          _commentController.clear();
          _rating = 0.0;
        });
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}


