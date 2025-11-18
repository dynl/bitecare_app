import 'package:flutter/material.dart';
import 'package:bitecare_app/services/api_service.dart';
import 'package:bitecare_app/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';

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
    final data = await ApiService.getUserProfile();
    if (mounted) {
      setState(() {
        _userData = data;
        _isLoading = false;
      });
    }
  }

  // --- NEW: PICK & UPLOAD IMAGE ---
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
      bool success = await ApiService.uploadAvatar(image);
      
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
                  backgroundColor: Colors.teal.shade100,
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
                        color: Colors.teal,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(blurRadius: 2, color: Colors.black26)],
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(email, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          
          const SizedBox(height: 40),
          
          // Info Cards
          Card(
            child: ListTile(
              leading: const Icon(Icons.phone, color: Colors.teal),
              title: const Text("Contact Number"),
              subtitle: Text(contact),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.verified_user, color: Colors.teal),
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