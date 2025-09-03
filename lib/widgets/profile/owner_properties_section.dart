import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/widgets/profile/owner_property_card.dart';
import 'package:unistay/views/add_property.dart';

class OwnerPropertiesSection extends StatelessWidget {
  final bool isTablet;

  const OwnerPropertiesSection({
    super.key,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final query = FirebaseFirestore.instance
        .collection('rooms')
        .where('ownerUid', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .withConverter<Room>(
      fromFirestore: (d, _) => Room.fromFirestore(d),
      toFirestore: (r, _) => <String, dynamic>{},
    );

    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot<Room>>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Text(
                  'Failed to load properties: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              return _buildPropertiesList(context, docs);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6E56CF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.home_work,
            color: Color(0xFF6E56CF),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'My Properties',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesList(BuildContext context, List<QueryDocumentSnapshot<Room>> docs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAddPropertyCard(context, docs.isEmpty),
        if (docs.isEmpty)
          _buildEmptyState()
        else
          ...docs.take(3).map((doc) => OwnerPropertyCard(room: doc.data())),
        if (docs.length > 3)
          _buildViewAllButton(context, docs.length),
      ],
    );
  }

  Widget _buildAddPropertyCard(BuildContext context, bool isEmpty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6E56CF).withOpacity(0.05),
            const Color(0xFF9C88FF).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6E56CF).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed(AddPropertyPage.route),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6E56CF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_home_work,
                    color: Color(0xFF6E56CF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Property',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEmpty
                            ? 'List your first property'
                            : 'List another property',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFF6C757D).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: const Color(0xFF6E56CF).withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.home_outlined,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No properties listed yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start by adding your first property above',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllButton(BuildContext context, int totalCount) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to a dedicated properties page or show dialog
            _showAllPropertiesDialog(context, totalCount);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF6E56CF).withOpacity(0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility,
                  color: const Color(0xFF6E56CF),
                  size: 20,
                ),
                const SizedBox(height: 8),
                Text(
                  'View All $totalCount Properties',
                  style: const TextStyle(
                    color: Color(0xFF6E56CF),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAllPropertiesDialog(BuildContext context, int totalCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('All Properties ($totalCount)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<QuerySnapshot<Room>>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .where('ownerUid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .where('status', isEqualTo: 'active')
                .withConverter<Room>(
              fromFirestore: (d, _) => Room.fromFirestore(d),
              toFirestore: (r, _) => <String, dynamic>{},
            ).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final room = docs[index].data();
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: room.photoUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              room.photoUrls.first,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.home, size: 16),
                                  ),
                            ),
                          )
                        : Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[300],
                            child: const Icon(Icons.home, size: 16),
                          ),
                    title: Text(
                      room.title,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${room.city}, ${room.price} CHF',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AddPropertyPage(propertyId: room.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}