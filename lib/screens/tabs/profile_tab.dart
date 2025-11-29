import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitecare_app/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bitecare_app/services/user_service.dart';
import 'package:bitecare_app/bitecare_theme.dart';
import 'package:bitecare_app/screens/login_screen.dart'; // Required for navigation

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploading = false; // To track upload status

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  void _fetchUser() async {
    final data = await UserService.getUserProfile();
    if (mounted) {
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    }
  }

  // --- PICK & UPLOAD IMAGE ---
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();

    // 1. Pick Image from Gallery
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery, // Change to .camera to take a photo
      imageQuality: 80, // Compress slightly for faster upload
    );

    if (image != null) {
      setState(() => _isUploading = true);

      // 2. Upload via API
      bool success = await UserService.uploadAvatar(image);

      if (mounted) {
        setState(() => _isUploading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated!")),
          );
          _fetchUser(); // Refresh user data to show new image URL
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image. Try again.")),
          );
        }
      }
    }
  }

  void _handleLogout() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout Confirmation"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // 1. Close the dialog
                Navigator.of(context).pop();

                // 2. Perform logout in provider (clear token)
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                authProvider.logout();

                // 3. FORCE Navigation to Login Screen & Clear History
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false, // This removes all previous routes
                );
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final name = _userData?['name'] ?? 'User';
    final email = _userData?['email'] ?? 'No email';
    final contact = _userData?['contact_number'] ?? 'Not provided';
    final avatarUrl = _userData?['avatar_url']; // URL from Laravel

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 30),

          // --- AVATAR SECTION ---
          Center(
            child: Stack(
              children: [
                // The Image
                CircleAvatar(
                  radius: 60,
                  backgroundColor: BiteCareTheme.primaryLightColor,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),

                // Loading Spinner (Overlay)
                if (_isUploading)
                  const Positioned.fill(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                // Edit Button (Camera Icon)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _isUploading ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2196F3), // Blue color
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(blurRadius: 2, color: Colors.black26),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(email, style: TextStyle(fontSize: 16, color: Colors.grey[600])),

          const SizedBox(height: 40),

          // Info Cards
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.phone,
                color: Color(0xFF2196F3),
              ), // Blue color
              title: const Text("Contact Number"),
              subtitle: Text(contact),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.verified_user,
                color: Color(0xFF2196F3),
              ), // Blue color
              title: const Text("Account Status"),
              subtitle: const Text("Active Member"),
            ),
          ),

          const Spacer(),

          // Logout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
