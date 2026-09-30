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

  void _initAuthListener() {
    currentUser.value = null; // Start unauthenticated
    try {
      _auth?.authStateChanges().listen((User? user) async {
        firebaseUser.value = user;
        if (user != null) {
          final dbService = Get.find<DatabaseService>();
          final profile = await dbService.getUserProfile(user.uid);
          if (profile != null) {
            currentUser.value = profile;
          } else {
            final newProfile = UserModel(
              id: user.uid,
              name: user.displayName ?? 'User',
              email: user.email ?? '',
              role: UserRole.candidate,
            );
            currentUser.value = newProfile;
            await dbService.saveUserProfile(newProfile);
          }
        } else {
          currentUser.value = null;
        }
      });
    } catch (_) {}
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      isLoading.value = true;
      if (_auth == null) {
        Get.snackbar(
          'Firebase Auth Offline',
          'Could not connect to Firebase Authentication',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return false;
      }

      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final dbService = Get.find<DatabaseService>();
        final profile = await dbService.getUserProfile(credential.user!.uid);
        if (profile != null) {
          currentUser.value = profile;
        } else {
          final newProfile = UserModel(
            id: credential.user!.uid,
            name: credential.user!.displayName ?? email.split('@')[0],
            email: email,
            role: UserRole.candidate,
          );
          currentUser.value = newProfile;
          await dbService.saveUserProfile(newProfile);
        }
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar(
        'Login Failed',
        e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim(),
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
      isLoading.value = true;
      if (_auth == null) {
        Get.snackbar(
          'Firebase Auth Offline',
          'Could not connect to Firebase Authentication',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return false;
      }

      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        await credential.user!.updateDisplayName(name);

        final newUser = UserModel(
          id: uid,
          name: name,
          email: email,
          role: role,
        );

        final dbService = Get.find<DatabaseService>();
        await dbService.saveUserProfile(newUser);
        currentUser.value = newUser;
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar(
        'Registration Failed',
        e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
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
  }
}
