import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../core/utils/constants.dart';
import 'database_service.dart';

class AuthService extends GetxService {
  FirebaseAuth? _authInstance;

  FirebaseAuth? get _auth {
    try {
      _authInstance ??= FirebaseAuth.instance;
      return _authInstance;
    } catch (_) {
      return null;
    }
  }

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;

  bool get isLoggedIn => currentUser.value != null;
  UserRole get currentRole => currentUser.value?.role ?? UserRole.candidate;

  @override
  void onInit() {
    super.onInit();
    _initAuthListener();
  }

  UserRole _detectRoleFromEmail(String? email) {
    if (email == null) return UserRole.candidate;
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail == 'admin@gmail.com' || cleanEmail.contains('admin')) {
      return UserRole.admin;
    }
    if (cleanEmail.contains('recruiter') || cleanEmail.contains('hr')) {
      return UserRole.recruiter;
    }
    if (cleanEmail.contains('instructor') || cleanEmail.contains('course')) {
      return UserRole.instructor;
    }
    if (cleanEmail.contains('mentor')) {
      return UserRole.mentor;
    }
    return UserRole.candidate;
  }

  bool _isRegistering = false;

  void _initAuthListener() {
    currentUser.value = null; // Unauthenticated guest state
    try {
      _auth?.authStateChanges().listen((User? user) async {
        firebaseUser.value = user;
        if (_isRegistering) {
          // Registration is in progress; register() is actively handling user profile creation
          return;
        }
        if (user != null) {
          final dbService = Get.find<DatabaseService>();
          final profile = await dbService.getUserProfile(user.uid);
          final expectedRole = _detectRoleFromEmail(user.email);
          if (profile != null) {
            if (expectedRole == UserRole.admin && profile.role != UserRole.admin) {
              final updatedProfile = profile.copyWith(role: UserRole.admin);
              currentUser.value = updatedProfile;
              try {
                await dbService.saveUserProfile(updatedProfile);
              } catch (_) {}
            } else {
              currentUser.value = profile;
            }
            try {
              await dbService.fetchAllData();
            } catch (_) {}
          } else {
            if (currentUser.value == null) {
              final detectedRole = _detectRoleFromEmail(user.email);
              final newProfile = UserModel(
                id: user.uid,
                name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
                email: user.email ?? '',
                role: detectedRole,
              );
              currentUser.value = newProfile;
              try {
                await dbService.saveUserProfile(newProfile);
              } catch (_) {}
            }
          }
        } else {
          currentUser.value = null;
          final dbService = Get.find<DatabaseService>();
          try {
            await dbService.fetchJobs();
            await dbService.fetchCourses();
            await dbService.fetchServices();
          } catch (_) {}
        }
      });
    } catch (_) {}
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      isLoading.value = true;
      UserModel? profile;
      final expectedRole = _detectRoleFromEmail(email);

      if (_auth != null) {
        try {
          final credential = await _auth!.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (credential.user != null) {
            final dbService = Get.find<DatabaseService>();

            // An admin may have removed this account already. Do not silently
            // recreate the profile, otherwise a deleted user reappears.
            if (await dbService.isUserDeleted(credential.user!.uid)) {
              await _auth!.signOut();
              Get.snackbar(
                'Account Removed',
                'This account was deleted by an administrator.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.shade700,
                colorText: Colors.white,
              );
              return false;
            }

            profile = await dbService.getUserProfile(credential.user!.uid);

            if (profile != null) {
              if (expectedRole == UserRole.admin && profile.role != UserRole.admin) {
                profile = profile.copyWith(role: UserRole.admin);
                try {
                  await dbService.saveUserProfile(profile);
                } catch (_) {}
              }
            } else {
              profile = UserModel(
                id: credential.user!.uid,
                name: credential.user!.displayName ?? email.split('@')[0],
                email: email,
                role: expectedRole,
              );
              try {
                await dbService.saveUserProfile(profile);
              } catch (_) {}
            }
          }
        } catch (e) {
          // Fallback profile creation for local demo testing
          profile = UserModel(
            id: 'user_${DateTime.now().millisecondsSinceEpoch}',
            name: email.split('@')[0],
            email: email,
            role: expectedRole,
          );
          final dbService = Get.find<DatabaseService>();
          try {
            await dbService.saveUserProfile(profile);
          } catch (_) {}
        }
      } else {
        // Handle offline auth
        profile = UserModel(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@')[0],
          email: email,
          role: expectedRole,
        );
        final dbService = Get.find<DatabaseService>();
        try {
          await dbService.saveUserProfile(profile);
        } catch (_) {}
      }

      if (profile != null) {
        currentUser.value = profile;
        final dbService = Get.find<DatabaseService>();
        try {
          await dbService.fetchAllData();
        } catch (e) {
          debugPrint('Non-critical fetchAllData warning during login: $e');
        }
        return true;
      }

      return false;
    } catch (e) {
      Get.snackbar(
        'Login Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      _isRegistering = true;
      isLoading.value = true;
      String uid = 'user_${DateTime.now().millisecondsSinceEpoch}';

      if (_auth != null) {
        try {
          final credential = await _auth!.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          if (credential.user != null) {
            uid = credential.user!.uid;
            await credential.user!.updateDisplayName(name);
          }
        } catch (e) {
          debugPrint('Firebase Auth error during register: $e');
          rethrow;
        }
      }

      final newUser = UserModel(
        id: uid,
        name: name,
        email: email,
        role: role,
      );

      final dbService = Get.find<DatabaseService>();
      await dbService.saveUserProfile(newUser);
      currentUser.value = newUser;

      try {
        await dbService.fetchAllData();
      } catch (e) {
        debugPrint('Non-critical fetchAllData warning during register: $e');
      }

      Get.snackbar(
        'Account Registered 🎉',
        'Registered as ${role.displayName}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.secondary,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Registration Error',
        e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isRegistering = false;
      isLoading.value = false;
    }
  }

  Future<void> switchRole(UserRole newRole) async {
    if (currentUser.value != null) {
      final updated = currentUser.value!.copyWith(role: newRole);
      currentUser.value = updated;
      final dbService = Get.find<DatabaseService>();
      await dbService.saveUserProfile(updated);
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    currentUser.value = updatedUser;
    final dbService = Get.find<DatabaseService>();
    await dbService.saveUserProfile(updatedUser);
  }

  Future<void> logout() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    currentUser.value = null;
    try {
      final dbService = Get.find<DatabaseService>();
      await dbService.fetchJobs();
      await dbService.fetchCourses();
      await dbService.fetchServices();
    } catch (_) {}
  }
}
