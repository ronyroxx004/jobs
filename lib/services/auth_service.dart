import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../core/utils/constants.dart';
import 'database_service.dart';

class AuthService extends GetxService {
  static const String _sessionUserKey = 'jobs_saved_session_user';
  static const String _sessionRoleKey = 'jobs_saved_session_role';

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
    _restoreLocalSession();
    _initAuthListener();
  }

  Future<void> ensureSessionLoaded() async {
    if (currentUser.value != null) return;
    await _restoreLocalSession();
  }

  Future<void> _persistSession(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUserKey, jsonEncode(user.toMap()));
      await prefs.setString(_sessionRoleKey, user.role.name);
      debugPrint('Persisted local session for ${user.email} (${user.role.name})');
    } catch (e) {
      debugPrint('Error persisting local session: $e');
    }
  }

  Future<void> _clearLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionUserKey);
      await prefs.remove(_sessionRoleKey);
      debugPrint('Cleared local session');
    } catch (e) {
      debugPrint('Error clearing local session: $e');
    }
  }

  Future<void> _restoreLocalSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_sessionUserKey);
      final savedRoleName = prefs.getString(_sessionRoleKey);
      if (userJson != null && userJson.trim().isNotEmpty) {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        var restored = UserModel.fromMap(map, map['id']?.toString() ?? '');
        if (savedRoleName != null && savedRoleName.isNotEmpty) {
          final matchedRole = UserRole.values.firstWhere(
            (r) => r.name == savedRoleName,
            orElse: () => restored.role,
          );
          restored = restored.copyWith(role: matchedRole);
        }
        if (currentUser.value == null) {
          currentUser.value = restored;
          debugPrint('Successfully restored local session: ${restored.email} with role: ${restored.role.name}');
        }
      }
    } catch (e) {
      debugPrint('Error restoring local session: $e');
    }
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
    if (cleanEmail.contains('instructor') ||
        cleanEmail.contains('course') ||
        cleanEmail.contains('trainer') ||
        cleanEmail.contains('trainor')) {
      return UserRole.instructor;
    }
    if (cleanEmail.contains('mentor')) {
      return UserRole.mentor;
    }
    return UserRole.candidate;
  }

  bool _isRegistering = false;

  void _initAuthListener() {
    try {
      _auth?.authStateChanges().listen((User? user) async {
        firebaseUser.value = user;
        if (_isRegistering) {
          // Registration is in progress; register() handles profile creation
          return;
        }

        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          final savedRoleName = prefs.getString(_sessionRoleKey);

          final dbService = Get.find<DatabaseService>();
          UserModel? profile = await dbService.getUserProfile(user.uid);
          if (profile == null && user.email != null) {
            profile = await dbService.getUserProfileByEmail(user.email!);
          }

          final expectedRole = _detectRoleFromEmail(user.email);
          final currentSessionRole = currentUser.value?.role;

          // Never downgrade an active mentor or admin session to candidate
          UserRole targetRole = profile?.role ?? expectedRole;
          if (currentSessionRole == UserRole.mentor ||
              savedRoleName == UserRole.mentor.name ||
              expectedRole == UserRole.mentor) {
            targetRole = UserRole.mentor;
          } else if (currentSessionRole == UserRole.admin ||
              savedRoleName == UserRole.admin.name ||
              expectedRole == UserRole.admin) {
            targetRole = UserRole.admin;
          } else if (currentSessionRole != null) {
            targetRole = currentSessionRole;
          }

          if (profile != null) {
            if (profile.role != targetRole) {
              profile = profile.copyWith(role: targetRole);
              try {
                await dbService.saveUserProfile(profile);
              } catch (_) {}
            }
            currentUser.value = profile;
            await _persistSession(profile);
            dbService.fetchAllData().catchError((e) {
              debugPrint('Background fetch error: $e');
            });
          } else {
            // Profile not yet found in database: check if we have an active local session for this user
            if (currentUser.value != null &&
                (currentUser.value!.id == user.uid ||
                    (user.email != null &&
                        currentUser.value!.email.toLowerCase() ==
                            user.email!.toLowerCase()))) {
              final activeUser = currentUser.value!.copyWith(role: targetRole);
              currentUser.value = activeUser;
              await _persistSession(activeUser);
              try {
                await dbService.saveUserProfile(activeUser);
              } catch (_) {}
            } else {
              final newProfile = UserModel(
                id: user.uid,
                name: user.displayName ?? user.email?.split('@')[0] ?? 'User',
                email: user.email ?? '',
                role: targetRole,
              );
              currentUser.value = newProfile;
              await _persistSession(newProfile);
              try {
                await dbService.saveUserProfile(newProfile);
              } catch (_) {}
            }
          }
        } else {
          // If firebaseUser is null, only clear if we don't have a persisted offline/demo session
          final prefs = await SharedPreferences.getInstance();
          final hasSavedSession = prefs.getString(_sessionUserKey) != null;
          if (!hasSavedSession) {
            currentUser.value = null;
            final dbService = Get.find<DatabaseService>();
            try {
              await dbService.fetchJobs();
              await dbService.fetchCourses();
              await dbService.fetchServices();
            } catch (_) {}
          }
        }
      });
    } catch (_) {}
  }

  Future<bool> login({
    required String email,
    required String password,
    UserRole? requestedRole,
  }) async {
    try {
      isLoading.value = true;
      UserModel? profile;
      final expectedRole = _detectRoleFromEmail(email);
      final effectiveRole = requestedRole ?? expectedRole;

      if (_auth != null) {
        try {
          final credential = await _auth!.signInWithEmailAndPassword(
            email: email,
            password: password,
          ).timeout(const Duration(seconds: 10), onTimeout: () {
            throw FirebaseAuthException(
              code: 'timeout',
              message: 'Authentication timed out. Please check your internet connection.',
            );
          });

          if (credential.user != null) {
            final dbService = Get.find<DatabaseService>();

            // An admin may have removed this account already
            if (await dbService.isUserDeleted(credential.user!.uid)) {
              await _auth!.signOut();
              await _clearLocalSession();
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
            profile ??= await dbService.getUserProfileByEmail(email);

            if (profile != null) {
              if (requestedRole != null && profile.role != requestedRole) {
                profile = profile.copyWith(role: requestedRole);
                try {
                  await dbService.saveUserProfile(profile);
                } catch (_) {}
              } else if (expectedRole == UserRole.admin && profile.role != UserRole.admin) {
                profile = profile.copyWith(role: UserRole.admin);
                try {
                  await dbService.saveUserProfile(profile);
                } catch (_) {}
              } else if (expectedRole == UserRole.mentor && profile.role != UserRole.mentor) {
                profile = profile.copyWith(role: UserRole.mentor);
                try {
                  await dbService.saveUserProfile(profile);
                } catch (_) {}
              }
            } else {
              profile = UserModel(
                id: credential.user!.uid,
                name: credential.user!.displayName ?? email.split('@')[0],
                email: email,
                role: effectiveRole,
              );
              try {
                await dbService.saveUserProfile(profile);
              } catch (_) {}
            }
          }
        } on FirebaseAuthException catch (e) {
          String message = 'Authentication failed';
          if (e.code == 'user-not-found') {
            message = 'No account found with this email. Please register first.';
          } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            message = 'Incorrect password. Please verify your credentials.';
          } else if (e.code == 'invalid-email') {
            message = 'The email address is formatted incorrectly.';
          } else if (e.code == 'user-disabled') {
            message = 'This account has been disabled.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many attempts. Please try again in a few moments.';
          } else {
            message = e.message ?? 'Authentication error (${e.code}).';
          }
          Get.snackbar(
            'Login Failed',
            message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return false;
        } catch (e) {
          debugPrint('Auth service error during login: $e');
          Get.snackbar(
            'Login Failed',
            'Could not sign in: ${e.toString()}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return false;
        }
      } else {
        // Offline / mock mode when Firebase is not initialized
        final dbService = Get.find<DatabaseService>();
        profile = await dbService.getUserProfileByEmail(email);
        if (profile == null) {
          Get.snackbar(
            'Account Not Found',
            'No account exists for $email. Please register first.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
          );
          return false;
        }
        if (requestedRole != null && profile.role != requestedRole) {
          profile = profile.copyWith(role: requestedRole);
          try {
            await dbService.saveUserProfile(profile);
          } catch (_) {}
        }
      }

      if (profile != null) {
        currentUser.value = profile;
        await _persistSession(profile);
        final dbService = Get.find<DatabaseService>();
        dbService.fetchAllData().catchError((e) {
          debugPrint('Non-critical fetchAllData warning during login: $e');
        });
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
      await _persistSession(newUser);

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
      await _persistSession(updated);
      final dbService = Get.find<DatabaseService>();
      await dbService.saveUserProfile(updated);
    }
  }

  Future<void> updateUserProfile(UserModel updatedUser) async {
    currentUser.value = updatedUser;
    await _persistSession(updatedUser);
    final dbService = Get.find<DatabaseService>();
    await dbService.saveUserProfile(updatedUser);
  }

  Future<void> logout() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    await _clearLocalSession();
    currentUser.value = null;
    try {
      final dbService = Get.find<DatabaseService>();
      await dbService.fetchJobs();
      await dbService.fetchCourses();
      await dbService.fetchServices();
    } catch (_) {}
  }
}
