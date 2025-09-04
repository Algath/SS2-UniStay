import 'package:flutter/material.dart';
import 'package:unistay/services/firestore_service.dart';
import 'package:unistay/models/user_profile.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _searchTerm = '';
  Map<String, dynamic>? _statistics;
  bool _isLoadingStats = true;
  String? _currentUserId; // Add this to track current user

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    _getCurrentUserId(); // Load current user ID
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Add method to get current user ID
  Future<void> _getCurrentUserId() async {
    try {
      // You'll need to implement this in your FirestoreService
      // or get it from your authentication service
      final userId = await _firestoreService.getCurrentUserId();
      setState(() {
        _currentUserId = userId;
      });
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _firestoreService.getUsersStatistics();
      setState(() {
        _statistics = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading statistics: $e')),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchTerm = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = isTablet
                ? (isLandscape ? constraints.maxWidth * 0.8 : constraints.maxWidth * 0.9)
                : double.infinity;

            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? (isLandscape ? 48 : 32) : 20,
                    vertical: isTablet ? 32 : 24,
                  ),
                  child: Column(
                    children: [
                      // Statistics Cards
                      _buildStatisticsSection(isTablet, isLandscape),
                      SizedBox(height: isTablet ? (isLandscape ? 32 : 24) : 20),

                      // Combined Users Management Section
                      _buildUsersSection(isTablet, isLandscape),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(bool isTablet, bool isLandscape) {
    if (_isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_statistics == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isTablet ? (isLandscape ? 32 : 28) : 24),
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
        child: const Text(
          'Failed to load statistics',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? (isLandscape ? 32 : 28) : 24),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.analytics_outlined, color: const Color(0xFF6E56CF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'App Statistics',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Users',
                  _statistics!['totalUsers'].toString(),
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Students',
                  _statistics!['students'].toString(),
                  Icons.school,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Homeowners',
                  _statistics!['homeowners'].toString(),
                  Icons.home,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Admins',
                  _statistics!['admins'].toString(),
                  Icons.admin_panel_settings,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6C757D),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Combined users section with integrated search
  Widget _buildUsersSection(bool isTablet, bool isLandscape) {
    return Container(
      width: double.infinity,
      height: isTablet ? 600 : 500, // Increased height to accommodate search
      padding: EdgeInsets.all(isTablet ? (isLandscape ? 32 : 28) : 24),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.people_outline, color: const Color(0xFF6E56CF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'User Management',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),

          // Search Bar (now integrated)
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search users by name or email...',
              hintStyle: TextStyle(color: const Color(0xFF6C757D)),
              prefixIcon: Icon(Icons.search, color: const Color(0xFF6E56CF)),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: const Color(0xFF6C757D)),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: const Color(0xFF6E56CF), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),

          // Users List
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _firestoreService.searchUsers(_searchTerm),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Trigger rebuild to retry
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchTerm.isNotEmpty ? Icons.search_off : Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchTerm.isNotEmpty
                              ? 'No users found matching "$_searchTerm"'
                              : 'No users found',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(user, isTablet);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build avatar fallback
  Widget _buildAvatarFallback(UserProfile user) {
    return Center(
      child: Text(
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 24,
        ),
      ),
    );
  }

// Helper method to build detail sections
  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF6E56CF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

// Updated helper method to build detail rows
  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor, bool isSelectable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6C757D),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: isSelectable
                ? SelectableText(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF2C3E50),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
                : Text(
              value.isEmpty ? 'Not provided' : value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF2C3E50),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user, bool isTablet) {
    // Check if this is the current user
    final isCurrentUser = _currentUserId != null && user.uid == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(isTablet ? 16 : 12),
        leading: Container(
          width: isTablet ? 56 : 48,
          height: isTablet ? 56 : 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6E56CF).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: user.photos.isNotEmpty
                ? Image.network(
              user.photos,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isTablet ? 20 : 18,
                  ),
                ),
              ),
            )
                : Center(
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 20 : 18,
                ),
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 16 : 14,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ),
            // Add "You" indicator for current user
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'You',
                  style: TextStyle(
                    color: const Color(0xFF6E56CF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: TextStyle(
                color: const Color(0xFF6C757D),
                fontSize: isTablet ? 14 : 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRoleChip(user.role),
                const SizedBox(width: 8),
                if (user.isAdmin) _buildAdminChip(),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            // Only show admin toggle if it's not the current user
            if (!isCurrentUser)
              PopupMenuItem(
                value: user.isAdmin ? 'remove_admin' : 'make_admin',
                child: Row(
                  children: [
                    Icon(
                      user.isAdmin ? Icons.admin_panel_settings_outlined : Icons.admin_panel_settings,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(user.isAdmin ? 'Remove Admin' : 'Make Admin'),
                  ],
                ),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color;
    switch (role.toLowerCase()) {
      case 'student':
        color = Colors.blue;
        break;
      case 'homeowner':
        color = Colors.green;
        break;
      case 'admin':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildAdminChip() {
    return Chip(
      label: const Text(
        'ADMIN',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.red.withOpacity(0.1),
      side: BorderSide(color: Colors.red.withOpacity(0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  void _handleUserAction(String action, UserProfile user) {
    switch (action) {
      case 'view':
        _showUserDetails(user);
        break;
      case 'make_admin':
      case 'remove_admin':
        _toggleAdminStatus(user);
        break;
    }
  }

  void _showUserDetails(UserProfile user) async {
    // Get property count for homeowners
    int propertyCount = 0;
    if (user.role.toLowerCase() == 'homeowner') {
      propertyCount = await _firestoreService.getUserPropertyCount(user.uid);
    }

    // Get university name for students
    String universityName = '';
    if (user.role.toLowerCase() == 'student' && user.uniAddress.isNotEmpty) {
      universityName = _firestoreService.getUniversityNameFromAddress(user.uniAddress);
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with user avatar and close button
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    // User Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: ClipOval(
                        child: user.photos.isNotEmpty
                            ? Image.network(
                          user.photos,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarFallback(user),
                        )
                            : _buildAvatarFallback(user),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // User Name and Role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.role.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Close Button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Basic Information Section
                      _buildDetailSection(
                        'Basic Information',
                        Icons.person_outline,
                        [
                          _buildDetailRow('Email', user.email, Icons.email_outlined),
                          _buildDetailRow('User ID', user.uid, Icons.fingerprint, isSelectable: true),
                          if (user.isAdmin)
                            _buildDetailRow('Admin Status', 'Yes', Icons.admin_panel_settings,
                                valueColor: Colors.red),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Role-specific Information
                      if (user.role.toLowerCase() == 'student') ...[
                        _buildDetailSection(
                          'Student Information',
                          Icons.school_outlined,
                          [
                            if (universityName.isNotEmpty)
                              _buildDetailRow('University', universityName, Icons.account_balance),
                            if (user.uniAddress.isNotEmpty)
                              _buildDetailRow('University Address', user.uniAddress, Icons.location_on_outlined),
                          ],
                        ),
                      ] else if (user.role.toLowerCase() == 'homeowner') ...[
                        _buildDetailSection(
                          'Homeowner Information',
                          Icons.home_outlined,
                          [
                            _buildDetailRow('Properties Listed', '$propertyCount', Icons.apartment,
                                valueColor: propertyCount > 0 ? Colors.green : Colors.grey),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildDetailRow(String label, String value) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 4.0),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         SizedBox(
  //           width: 100,
  //           child: Text(
  //             '$label:',
  //             style: const TextStyle(fontWeight: FontWeight.bold),
  //           ),
  //         ),
  //         Expanded(
  //           child: Text(value.isEmpty ? 'Not provided' : value),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _toggleAdminStatus(UserProfile user) {
    final newStatus = !user.isAdmin;
    final action = newStatus ? 'grant' : 'revoke';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action == 'grant' ? 'Grant' : 'Revoke'} Admin Access'),
        content: Text(
          'Are you sure you want to $action admin access ${action == 'grant' ? 'to' : 'from'} ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _firestoreService.updateUserAdminStatus(user.uid, newStatus);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Admin access ${action}d successfully'),
                    ),
                  );
                  _loadStatistics(); // Refresh statistics
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.orange,
            ),
            child: Text('${action == 'grant' ? 'Grant' : 'Revoke'} Access'),
          ),
        ],
      ),
    );
  }
}