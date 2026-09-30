import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../core/utils/constants.dart';
import '../core/routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  final Rx<UserRole> selectedRole = UserRole.candidate.obs;
  final RxBool isPasswordVisible = false.obs;

  bool get isLoading => _authService.isLoading.value;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void selectRole(UserRole role) {
    selectedRole.value = role;
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter email and password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final success = await _authService.login(email: email, password: password);
    if (success) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Required',
        'Please fill in all registration fields',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final success = await _authService.register(
      name: name,
      email: email,
      password: password,
      role: selectedRole.value,
    );

    if (success) {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  void switchRoleAndNavigate(UserRole newRole) async {
    await _authService.switchRole(newRole);
    Get.snackbar(
      'Role Switched',
      'You are now viewing as ${newRole.displayName}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
  }

  void logout() async {
    await _authService.logout();
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
