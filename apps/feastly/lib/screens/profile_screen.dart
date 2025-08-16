import 'package:feastly/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;
  bool _didInit = false;
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show error message if any - schedule after build to avoid calling during build
    if (_errorMessage != null) {
      final msg = _errorMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      });
      _errorMessage = null;
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _user = User(
        id: '1',
        name: 'John Doe',
        email: 'customer@example.com',
        role: UserRole.customer,
        phoneNumber: '1234567890',
        addresses: ['123 Main St'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      // }
    } catch (e) {
      // Defer showing UI-dependent messages — store and show in didChangeDependencies.
      _errorMessage = 'Error loading profile: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      context.read<AuthBloc>().add(LogOut());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? _buildErrorState()
          : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Could not load profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserData,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final theme = Theme.of(context);
    final user = _user!;

    return CustomScrollView(
      slivers: [
        // App Bar with Profile Header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    _buildProfileAvatar(user),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Main Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Section
                _buildSectionHeader('Account'),
                _buildAccountCard(),

                const SizedBox(height: 24),

                // Orders & Payments Section
                _buildSectionHeader('Orders & Payments'),
                _buildOrdersPaymentsCard(),

                const SizedBox(height: 24),

                // Preferences Section
                _buildSectionHeader('Preferences'),
                _buildPreferencesCard(),

                const SizedBox(height: 24),

                // Support Section
                _buildSectionHeader('Support'),
                _buildSupportCard(),

                const SizedBox(height: 32),

                // Logout Button
                _buildLogoutButton(),

                const SizedBox(height: 24),

                // App Version
                Center(
                  child: Text(
                    'Feastly v1.0.0',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(User user) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.white,
      child: user.profileImageUrl != null
          ? ClipOval(
              child: Image.network(
                user.profileImageUrl!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
            )
          : Text(
              user.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildAccountCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'Manage your personal details',
            onTap: () {
              // Navigate to personal info screen
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.location_on_outlined,
            title: 'Saved Addresses',
            subtitle: '${_user?.addresses.length ?? 0} addresses saved',
            onTap: () {
              // Navigate to addresses screen
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.favorite_border,
            title: 'Favorite Restaurants',
            subtitle: 'View your favorite places',
            onTap: () {
              // Navigate to favorites screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersPaymentsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'Order History',
            subtitle: 'View your past orders',
            onTap: () {
              context.go('/orders');
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.payment_outlined,
            title: 'Payment Methods',
            subtitle: 'Manage your payment options',
            onTap: () {
              // Navigate to payment methods screen
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.local_offer_outlined,
            title: 'Promos & Credits',
            subtitle: 'Manage your offers and credits',
            onTap: () {
              // Navigate to promos screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            subtitle: 'Manage how you receive notifications',
            onTap: () {
              // Navigate to notification settings
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: () {
              // Show language picker
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Off',
            onTap: () {
              // Toggle dark mode
            },
            trailing: Switch(
              value: false,
              onChanged: (value) {
                // Toggle dark mode
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'Get help with your orders',
            onTap: () {
              // Navigate to help center
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.info_outline,
            title: 'About Feastly',
            subtitle: 'Terms, Privacy, and more',
            onTap: () {
              // Navigate to about screen
            },
          ),
          const Divider(height: 1),
          _buildSettingsTile(
            icon: Icons.star_border,
            title: 'Rate Feastly',
            subtitle: 'Tell us what you think',
            onTap: () {
              // Open app rating
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.red[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
