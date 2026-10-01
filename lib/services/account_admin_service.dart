import 'package:get/get.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Result of a server-side account deletion.
class DeleteAccountResult {
  /// Whether the Firebase Auth account itself was removed.
  final bool authDeleted;

  /// Set when the Auth deletion failed but data cleanup still succeeded.
  final String? authError;

  /// Number of records removed per Realtime Database collection.
  final Map<String, int> realtimeRemoved;

  final String email;

  const DeleteAccountResult({
    required this.authDeleted,
    required this.authError,
    required this.realtimeRemoved,
    required this.email,
  });

  int get totalRemoved =>
      realtimeRemoved.values.fold(0, (sum, value) => sum + value);
}

/// Calls the `deleteUserAccount` Cloud Function, which is the only place a
/// Firebase Auth account for *another* user can be deleted from.
///
/// Falls back to a plain sign-out-safe error when the function is not deployed.
class AccountAdminService extends GetxService {
  static const String _functionName = 'deleteUserAccount';

  FirebaseFunctions? get _functions {
    try {
      return FirebaseFunctions.instance;
    } catch (_) {
      return null;
    }
  }

  /// Throws [AccountDeletionUnavailable] when the callable is not deployed.
  Future<DeleteAccountResult> deleteAccount(String uid) async {
    final functions = _functions;
    if (functions == null) {
      throw const AccountDeletionUnavailable(
        'Cloud Functions are not initialised.',
      );
    }

    if (FirebaseAuth.instance.currentUser == null) {
      throw const AccountDeletionUnavailable('You are not signed in.');
    }

    try {
      // cloud_functions 5.x takes the payload positionally.
      final result = await functions
          .httpsCallable(_functionName)
          .call<Map<String, dynamic>?>({'uid': uid});

      final data = result.data ?? const <String, dynamic>{};
      final removed = <String, int>{};
      final rawRemoved = data['realtimeRemoved'];
      if (rawRemoved is Map) {
        rawRemoved.forEach((key, value) {
          if (value is int) removed['$key'] = value;
        });
      }

      return DeleteAccountResult(
        authDeleted: data['authDeleted'] == true,
        authError: data['authError'] as String?,
        realtimeRemoved: removed,
        email: data['email'] as String? ?? '',
      );
    } on FirebaseFunctionsException catch (e) {
      // not-found / unimplemented means the function has not been deployed.
      final code = e.code.toLowerCase();
      if (code.contains('not-found') || code.contains('unimplemented')) {
        throw const AccountDeletionUnavailable(
          'The deleteUserAccount function is not deployed. '
          'Run: firebase deploy --only functions',
        );
      }
      if (code.contains('permission-denied') ||
          code.contains('unauthenticated')) {
        throw AccountDeletionUnavailable(
          'Admin access denied. Sign in as admin@gmail.com.',
        );
      }
      throw AccountDeletionUnavailable(e.message ?? e.code);
    } catch (e) {
      throw AccountDeletionUnavailable(e.toString());
    }
  }

  /// Probes whether `deleteUserAccount` is deployed.
  ///
  /// Sends an empty payload: our function rejects it with `invalid-argument`,
  /// which proves the function exists. `not-found` / `unimplemented` means it is
  /// not deployed yet.
  Future<bool> isDeployed() async {
    final functions = _functions;
    if (functions == null) return false;
    if (FirebaseAuth.instance.currentUser == null) return false;

    try {
      await functions
          .httpsCallable(_functionName)
          .call<Map<String, dynamic>?>({});
      // No error means the callable exists (unexpected for an empty payload).
      return true;
    } on FirebaseFunctionsException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('invalid-argument')) return true;
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Raised when the callable cannot be used, so the UI can fall back or explain.
class AccountDeletionUnavailable implements Exception {
  final String message;
  const AccountDeletionUnavailable(this.message);

  @override
  String toString() => message;
}