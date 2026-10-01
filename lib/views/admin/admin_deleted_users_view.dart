import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../controllers/admin_controller.dart';
import '../../core/utils/constants.dart';
import '../../models/deleted_user_model.dart';
import 'admin_shared.dart';

/// Admin screen listing accounts that were removed, with a Restore option.
///
/// Restoring brings back the login and profile only - the content that was
/// deleted with the account is not recoverable.
class AdminDeletedUsersView extends StatefulWidget {
  const AdminDeletedUsersView({super.key});

  @override
  State<AdminDeletedUsersView> createState() => _AdminDeletedUsersViewState();
}

class _AdminDeletedUsersViewState extends State<AdminDeletedUsersView> {
  final AdminController controller = Get.find<AdminController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _query = ''.obs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await controller.refreshDeletedUsers();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Deleted Users',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text(
              'Restore by ID',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            onPressed: () => _showRestoreByIdDialog(context),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    _buildNotice(),
                    _buildSearch(),
                    Expanded(child: _buildList()),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Restoring an account re-enables its login and recreates the '
              'profile. Resumes, applications, jobs, mentorship sessions and '
              'chats were deleted permanently and cannot be brought back.',
              style: GoogleFonts.inter(fontSize: 11, height: 1.5, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => _query.value = value,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name, email, or User ID...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: Obx(
            () => _query.value.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _query.value = '';
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Obx(() {
      final q = _query.value.toLowerCase().trim();
      final items = controller.deletedUsers
          .where((u) =>
              q.isEmpty ||
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.id.toLowerCase().contains(q))
          .toList();

      if (items.isEmpty) {
        if (!controller.deletedUsersLoaded.value) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AdminEmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load deleted accounts',
                    subtitle:
                        'The database denied this read or no accounts were found.\n'
                        'Deploy latest rules: firebase deploy --only database\n\n'
                        'You can still restore an account directly by entering its User ID below.',
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Restore by User ID'),
                    onPressed: () => _showRestoreByIdDialog(context),
                  ),
                ],
              ),
            ),
          );
        }
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AdminEmptyState(
                  icon: Icons.restore_rounded,
                  title: 'No deleted accounts',
                  subtitle:
                      'Accounts removed by an admin appear here so you can restore them.\n\n'
                      'Have an account ID from Realtime Database at deleted_users? '
                      'Tap below to restore it directly.',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Restore by User ID'),
                  onPressed: () => _showRestoreByIdDialog(context),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _DeletedUserCard(record: items[index]),
      );
    });
  }

  void _showRestoreByIdDialog(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final Rx<UserRole> selectedRole = UserRole.candidate.obs;
    final RxBool isSubmitting = false.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restore_rounded,
                  color: AppColors.secondary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Restore Account by ID',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter or paste the User ID found in Realtime Database at deleted_users/{id}.',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: idController,
                style: GoogleFonts.robotoMono(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'User ID (UID) *',
                  hintText: 'e.g. 5qO8Yd...',
                  prefixIcon:
                      const Icon(Icons.fingerprint_rounded, size: 20),
                  suffixIcon: IconButton(
                    tooltip: 'Paste from clipboard',
                    icon: const Icon(Icons.paste_rounded, size: 20),
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null &&
                          data!.text!.trim().isNotEmpty) {
                        final pasted = data.text!.trim();
                        idController.text = pasted;
                        final match =
                            controller.deletedUsers.firstWhereOrNull(
                          (u) => u.id == pasted,
                        );
                        if (match != null) {
                          if (match.name.isNotEmpty) {
                            nameController.text = match.name;
                          }
                          if (match.email.isNotEmpty) {
                            emailController.text = match.email;
                          }
                          selectedRole.value = UserRole.values.firstWhere(
                            (r) =>
                                r.name.toLowerCase() ==
                                match.role.toLowerCase(),
                            orElse: () => UserRole.candidate,
                          );
                        }
                      }
                    },
                  ),
                ),
                onChanged: (val) {
                  final trimmed = val.trim();
                  final match = controller.deletedUsers.firstWhereOrNull(
                    (u) => u.id == trimmed,
                  );
                  if (match != null) {
                    if (nameController.text.isEmpty &&
                        match.name.isNotEmpty) {
                      nameController.text = match.name;
                    }
                    if (emailController.text.isEmpty &&
                        match.email.isNotEmpty) {
                      emailController.text = match.email;
                    }
                    selectedRole.value = UserRole.values.firstWhere(
                      (r) =>
                          r.name.toLowerCase() == match.role.toLowerCase(),
                      orElse: () => UserRole.candidate,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Name (optional)',
                  hintText: 'e.g. John Doe',
                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  hintText: 'e.g. user@example.com',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Role',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700]),
              ),
              const SizedBox(height: 6),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: UserRole.values.map((role) {
                    final selected = selectedRole.value == role;
                    return ChoiceChip(
                      label: Text(
                        role.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.secondary,
                      onSelected: (val) {
                        if (val) selectedRole.value = role;
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                  color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
          ),
          Obx(
            () => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting.value
                  ? null
                  : () async {
                      final uid = idController.text.trim();
                      if (uid.isEmpty) {
                        Get.snackbar(
                          'User ID Required',
                          'Please enter a valid User ID to restore.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                        return;
                      }
                      isSubmitting.value = true;
                      Get.back();
                      await controller.restoreUserById(
                        uid,
                        name: nameController.text.trim().isNotEmpty
                            ? nameController.text.trim()
                            : null,
                        email: emailController.text.trim().isNotEmpty
                            ? emailController.text.trim()
                            : null,
                        role: selectedRole.value,
                      );
                      await _load();
                    },
              child: isSubmitting.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Restore Account',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeletedUserCard extends StatelessWidget {
  final DeletedUserModel record;

  const _DeletedUserCard({required this.record});

  Color get _accent => switch (record.role) {
        'recruiter' => AppColors.secondary,
        'mentor' => AppColors.accent,
        'instructor' => AppColors.warning,
        'admin' => Colors.redAccent,
        _ => AppColors.primary,
      };

  String _formatDate(DateTime date) {
    try {
      return DateFormat('d MMM yyyy, h:mm a').format(date);
    } catch (_) {
      return date.toString();
    }
  }

  String _prettyRole(String role) {
    switch (role) {
      case 'recruiter':
        return 'Recruiter';
      case 'mentor':
        return 'Mentor';
      case 'instructor':
        return 'Instructor';
      case 'admin':
        return 'Admin';
      case 'candidate':
        return 'Candidate';
      default:
        return role.isEmpty ? 'Unknown' : role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final label = record.name.isNotEmpty
        ? record.name
        : (record.email.isNotEmpty ? record.email : 'User (${record.id})');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _accent.withValues(alpha: 0.15),
                  child: Text(
                    label.isEmpty ? '?' : label[0].toUpperCase(),
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildInfo(label, _accent)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Restore'),
                    onPressed: () => _confirmRestore(context, controller),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text('Purge'),
                    onPressed: () => _confirmPurge(context, controller),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String label, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          record.email.isEmpty ? 'No email recorded' : record.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Flexible(
              child: Text(
                'UID: ${record.id}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                Clipboard.setData(ClipboardData(text: record.id));
                Get.snackbar(
                  'Copied',
                  'User ID copied: ${record.id}',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _prettyRole(record.role),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Deleted ${_formatDate(record.deletedAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmRestore(BuildContext context, AdminController controller) {
    final displayName = record.name.isNotEmpty
        ? record.name
        : (record.email.isNotEmpty ? record.email : 'UID: ${record.id}');

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Restore this account?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          '$displayName will be able to '
          'log in again and will reappear in the candidate, recruiter, mentor '
          'and instructor lists.\n\nTheir deleted resumes, applications, jobs, '
          'sessions and chats will NOT come back.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Get.back();
              await controller.restoreUser(record);
            },
            child: Text(
              'Restore',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPurge(BuildContext context, AdminController controller) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Permanently remove this record?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.red.shade600,
          ),
        ),
        content: Text(
          'The restore record for '
          '${record.email.isEmpty ? record.name : record.email} will be deleted '
          'permanently and this cannot be undone.\n\n'
          'They can still sign in again with their old email and password, which '
          'recreates an empty profile - but you will not be able to restore '
          'them from here.',
          style: GoogleFonts.inter(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Get.back();
              await controller.purgeDeletedUser(record);
            },
            child: Text(
              'Purge',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}