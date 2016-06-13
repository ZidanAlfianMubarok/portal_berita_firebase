import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _apiService = AuthService();
  User? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = _apiService.currentUser;
    _nameController.text = _user?.displayName ?? '';
  }

  void _updateProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _apiService.updateName(_nameController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteAccount() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
                'Are you sure you want to delete your account? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.deleteAccount();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Error: ${e.toString()}. You might need to re-login to delete account.")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent, // Modern look
        foregroundColor: Colors.black, // Dark icon/text
      ),
      body: SingleChildScrollView(
        // For smaller screens
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(
                      _user?.displayName?.isNotEmpty == true
                          ? _user!.displayName![0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child:
                          Icon(Icons.edit, color: Colors.deepPurple, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _user?.displayName ?? 'No Name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              _user?.email ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                prefixIcon: const Icon(Icons.person_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('UPDATE PROFILE',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
            const SizedBox(height: 40),
            // Danger Zone
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger Zone',
                    style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout',
                        style: TextStyle(color: Colors.red)),
                    onTap: () async {
                      await _apiService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const Divider(color: Colors.redAccent),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Delete Account',
                        style: TextStyle(color: Colors.red)),
                    onTap: _isLoading ? null : _deleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
