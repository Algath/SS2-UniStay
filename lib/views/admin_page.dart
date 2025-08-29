import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> _refresh() async {
    await FirebaseFirestore.instance.clearPersistence();
    await FirebaseFirestore.instance.terminate();

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Users', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Total Users', FirebaseFirestore.instance.collection('users')),
                _buildStatCard('Total Properties', FirebaseFirestore.instance.collection('rooms')),
              ],
            ),
            const SizedBox(height: 24),
            const Text('User List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildUserList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, CollectionReference ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 140,
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;

        return ListView.separated(
          separatorBuilder: (_, __) => const Divider(height: 1),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(backgroundImage: NetworkImage(user['avatarUrl'] ?? '')),
              title: Text(user['fullName'] ?? 'No name'),
              subtitle: Text(user['userType'] ?? 'Unknown'),
              trailing: _buildUserAction(user),
            );
          },
        );
      },
    );
  }

  Widget _buildUserAction(Map<String, dynamic> user) {
    final userType = user['userType'] ?? 'Student';
    if (userType == 'Student') {
      return const Icon(Icons.block, color: Colors.red);
    } else {
      return const Icon(Icons.undo, color: Colors.green);
    }
  }
}
