import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../core/utils/constants.dart';
import '../core/routes/app_routes.dart';
import 'home_controller.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  
  final Rx<UserRole> selectedRole = UserRole.candidate.obs;
  final RxBool isPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  bool get isLoading => _authService.isLoading.value;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void selectRole(UserRole role) {
    selectedRole.value = role;
  }

  void _goHomeIfNeeded() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().currentIndex.value = 0;
    }
    // Re-navigating to the route we are already on leaves a redundant
    // transition on the stack and can leave the shell blank and unresponsive.
    if (Get.currentRoute == AppRoutes.home) return;
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter email and password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    final success = await _authService.login(
      email: email,
      password: password,
    );
    if (success) {
      Get.closeAllSnackbars();
      _goHomeIfNeeded();
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
        backgroundColor: Colors.red.withValues(alpha: 0.8),
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
      Get.closeAllSnackbars();
      _goHomeIfNeeded();
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
    if (Get.isDialogOpen == true) Get.back();
    if (Get.isBottomSheetOpen == true) Get.back();
    Get.closeAllSnackbars();
    
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    selectedRole.value = UserRole.candidate;

    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().currentIndex.value = 0;
    }

    await _authService.logout();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute == AppRoutes.home) {
        return;
      }
      Get.offAllNamed(AppRoutes.home);
    });
  }
}
