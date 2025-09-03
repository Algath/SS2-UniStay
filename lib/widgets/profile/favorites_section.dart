import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/services/favorites_service.dart';
import 'package:unistay/views/property_detail.dart';

class FavoritesSection extends StatelessWidget {
  final bool isTablet;
  const FavoritesSection({super.key, this.isTablet = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
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
          _buildHeader(),
          SizedBox(height: isTablet ? 20 : 16),
          StreamBuilder<Set<String>>(
            stream: FavoritesService.favoritesStream(),
            builder: (context, favSnap) {
              if (favSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final ids = favSnap.data ?? const <String>{};
              if (ids.isEmpty) {
                return _buildEmpty();
              }
              return FutureBuilder<List<Room>>(
                future: _fetchRoomsFor(ids.toList()),
                builder: (context, roomSnap) {
                  if (roomSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rooms = roomSnap.data ?? const <Room>[];
                  if (rooms.isEmpty) return _buildEmpty();
                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _FavoriteTile(room: rooms[i]),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6E56CF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bookmark, color: Color(0xFF6E56CF), size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          'Favorites',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: [
        Icon(Icons.bookmark_border, color: Colors.grey[400], size: 48),
        const SizedBox(height: 8),
        Text('No favorites yet', style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Save listings to see them here', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
      ],
    );
  }

  Future<List<Room>> _fetchRoomsFor(List<String> ids) async {
    final List<Room> out = [];
    // Firestore whereIn limit is 10; chunk if necessary
    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10);
      final qs = await FirebaseFirestore.instance
          .collection('rooms')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      out.addAll(qs.docs.map((d) => Room.fromFirestore(d)));
    }
    // Keep original order of ids if possible
    out.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return out;
  }
}

class _FavoriteTile extends StatelessWidget {
  final Room room;
  const _FavoriteTile({required this.room});

  @override
  Widget build(BuildContext context) {
    final img = room.photoUrls.isNotEmpty ? room.photoUrls.first : null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PropertyDetailPage(roomId: room.id)),
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: img == null
              ? Container(width: 56, height: 56, color: Colors.grey[200], child: Icon(Icons.apartment, color: Colors.grey[400]))
              : Image.network(
                  img,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400])),
                ),
        ),
        title: Text(room.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('CHF ${room.price}/month · ${room.sizeSqm} m²'),
        trailing: IconButton(
          tooltip: 'Remove',
          icon: const Icon(Icons.bookmark, color: Color(0xFF6E56CF)),
          onPressed: () async {
            await FavoritesService.toggleFavorite(room.id);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from favorites')));
          },
        ),
      ),
    );
  }
}


