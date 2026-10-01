import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/user_model.dart';

class AdminRoleUsersView extends GetView<AdminController> {
  final UserRole role;
  const AdminRoleUsersView({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final users = controller.allUsers.where((u) => u.role == role).toList();
        if (users.isEmpty) {
          return Center(
            child: Text(
              'No ${role.name}s found',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 15),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        color: AppColors.secondary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(user.name,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: Text(
                    '${user.email}\n${user.headline.isNotEmpty ? user.headline : user.location}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded,
                          color: AppColors.primary),
                      tooltip: 'View & Edit Details',
                      onPressed: () => _showEditUserDialog(context, user),
                    ),
                    if (role == UserRole.candidate)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete Candidate',
                        onPressed: () =>
                            controller.deleteUser(user.id, user.name),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showEditUserDialog(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final headlineController = TextEditingController(text: user.headline);
    final bioController = TextEditingController(text: user.bio);
    final locationController = TextEditingController(text: user.location);
    final experienceController =
        TextEditingController(text: user.experienceYears.toString());

    Get.dialog(
      AlertDialog(
        title: Text('Edit ${user.name}',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: headlineController,
                decoration: const InputDecoration(labelText: 'Headline'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: experienceController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Experience Years'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updated = user.copyWith(
                name: nameController.text.trim(),
                email: emailController.text.trim(),
                headline: headlineController.text.trim(),
                bio: bioController.text.trim(),
                location: locationController.text.trim(),
                experienceYears:
                    int.tryParse(experienceController.text.trim()) ??
                        user.experienceYears,
              );
              controller.updateUserProfile(updated);
              Get.back();
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
