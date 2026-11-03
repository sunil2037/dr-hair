import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/appointments/presentation/clinic_appointment_cubit.dart';
import '../../features/auth/presentation/viewmodels/auth_cubit.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';
import '../../features/care/presentation/viewmodels/care_cubit.dart';
import '../../features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import '../../features/shop/presentation/viewmodels/cart_cubit.dart';
import '../routes/app_router.dart';
import '../routes/route_names.dart';
import '../storage/app_local_cache.dart';
import '../widgets/app_toast.dart';

/// Central coordinator managing the authenticated patient lifecycle,
/// binding patient-scoped state on sign-in, and reliably clearing cached
/// patient data and clinical state on sign-out or account switch.
class SessionCoordinator {
  static final SessionCoordinator instance = SessionCoordinator._();

  SessionCoordinator._({AppLocalCache? cache})
    : _cache = cache ?? AppLocalCache.instance;

  final AppLocalCache _cache;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastBoundPatientId;

  AuthCubit? _authCubit;
  CareCubit? _careCubit;
  CartCubit? _cartCubit;
  ClinicAppointmentCubit? _appointmentCubit;
  HairTestCubit? _hairTestCubit;
  bool _isBlockedDialogShowing = false;

  /// Attaches listeners to cubits to synchronize patient scope automatically.
  void attach({
    required AuthCubit authCubit,
    required CareCubit careCubit,
    required CartCubit cartCubit,
    required ClinicAppointmentCubit appointmentCubit,
    required HairTestCubit hairTestCubit,
  }) {
    _authCubit = authCubit;
    _careCubit = careCubit;
    _cartCubit = cartCubit;
    _appointmentCubit = appointmentCubit;
    _hairTestCubit = hairTestCubit;

    _authSubscription?.cancel();
    _authSubscription = authCubit.stream.listen((state) {
      _handleAuthStateChange(
        state: state,
        careCubit: careCubit,
        cartCubit: cartCubit,
        appointmentCubit: appointmentCubit,
        hairTestCubit: hairTestCubit,
      );
    });

    // Handle initial state if already authenticated
    _handleAuthStateChange(
      state: authCubit.state,
      careCubit: careCubit,
      cartCubit: cartCubit,
      appointmentCubit: appointmentCubit,
      hairTestCubit: hairTestCubit,
    );
  }

  void _handleAuthStateChange({
    required AuthState state,
    required CareCubit careCubit,
    required CartCubit cartCubit,
    required ClinicAppointmentCubit appointmentCubit,
    required HairTestCubit hairTestCubit,
  }) {
    if (state.status == AuthStatus.authenticated && state.user != null) {
      final patientId = state.user?.patientId ?? state.user?.id.toString();
      if (patientId != null &&
          patientId.isNotEmpty &&
          patientId != _lastBoundPatientId) {
        _lastBoundPatientId = patientId;
        final token = state.sessionToken;
        careCubit.bindPatient(patientId, sessionToken: token);
        hairTestCubit.bindPatient(patientId, sessionToken: token);
        if (token != null && token.isNotEmpty) {
          appointmentCubit.loadFromApi(token).catchError((_) {});
        }
      }
    } else if (state.status == AuthStatus.unauthenticated &&
        _lastBoundPatientId != null) {
      final oldPatientId = _lastBoundPatientId!;
      _lastBoundPatientId = null;
      unawaited(
        clearPatientSession(
          patientId: oldPatientId,
          careCubit: careCubit,
          cartCubit: cartCubit,
          appointmentCubit: appointmentCubit,
          hairTestCubit: hairTestCubit,
        ),
      );
    }
  }

  /// Completely clears patient-scoped local storage, in-memory state, and caches.
  Future<void> clearPatientSession({
    required String patientId,
    CareCubit? careCubit,
    CartCubit? cartCubit,
    ClinicAppointmentCubit? appointmentCubit,
    HairTestCubit? hairTestCubit,
  }) async {
    await _cache.clearPatientScopedData(patientId);
    await careCubit?.clearPersonalCareData();
    await careCubit?.bindPatient(null);
    await hairTestCubit?.clearSavedAssessment();
    await hairTestCubit?.bindPatient(null);
    await appointmentCubit?.clearForPatient(patientId);
    cartCubit?.clear();

    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}
  }

  /// Convenience sign-out helper that clears all patient stores and signs out.
  Future<void> signOut(BuildContext context) async {
    final authCubit = context.read<AuthCubit?>();
    final hairCubit = context.read<HairTestCubit?>();
    final careCubit = context.read<CareCubit?>();
    final cartCubit = context.read<CartCubit?>();
    final appointmentCubit = context.read<ClinicAppointmentCubit?>();
    final patientId =
        authCubit?.state.user?.patientId ?? _lastBoundPatientId ?? 'GUEST';

    _lastBoundPatientId = null;
    await clearPatientSession(
      patientId: patientId,
      careCubit: careCubit,
      cartCubit: cartCubit,
      appointmentCubit: appointmentCubit,
      hairTestCubit: hairCubit,
    );
    await authCubit?.signOut();
  }

  /// When an account is deleted by administrator: flushes patient session,
  /// displays notification, and redirects user to signin screen.
  Future<void> handleAccountDeleted({String? message, BuildContext? context}) async {
    final patientId = _authCubit?.state.user?.patientId ?? _lastBoundPatientId ?? 'GUEST';
    _lastBoundPatientId = null;

    await clearPatientSession(
      patientId: patientId,
      careCubit: _careCubit,
      cartCubit: _cartCubit,
      appointmentCubit: _appointmentCubit,
      hairTestCubit: _hairTestCubit,
    );
    await _cache.remove('has_completed_hair_test');
    await _cache.remove('has_skipped_hair_test');
    await _cache.remove('hair_test_stage');
    await _authCubit?.signOut();

    final targetContext = context ?? AppRouter.rootNavigatorKey.currentContext;
    if (targetContext != null && targetContext.mounted) {
      AppToast.show(
        targetContext,
        SnackBar(
          backgroundColor: const Color(0xFFC53030),
          content: Text(
            message ?? 'Your account has been deleted by clinic administration.',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      try {
        AppRouter.router.go(RouteNames.signin);
      } catch (_) {}
    }
  }

  /// Displays a non-dismissible warning dialog when an account has been suspended/blocked
  /// by clinic administration, with unblock method instructions and direct contact actions.
  Future<void> showAccountBlockedDialog({
    BuildContext? context,
    String? message,
    String? supportPhone = '+91-9876543210',
    String? supportEmail = 'support@drhair.in',
  }) async {
    if (_isBlockedDialogShowing) return;
    final targetContext = context ?? AppRouter.rootNavigatorKey.currentContext;
    if (targetContext == null || !targetContext.mounted) return;

    _isBlockedDialogShowing = true;

    final phone = (supportPhone != null && supportPhone.isNotEmpty) ? supportPhone : '+91-9876543210';
    final email = (supportEmail != null && supportEmail.isNotEmpty) ? supportEmail : 'support@drhair.in';
    final desc = (message != null && message.isNotEmpty)
        ? message
        : 'Your Dr. Hair account has been suspended by clinic administration.';

    try {
      await showDialog<void>(
        context: targetContext,
        barrierDismissible: false,
        builder: (dialogCtx) => PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFEB2B2)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shield_outlined,
                        color: Color(0xFFE53E3E),
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Account Suspended',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4A5568),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How to regain access & unblock:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Please reach out to Dr. Hair Clinic Support with your registered phone number or patient ID:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF718096)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF1A365D)),
                            const SizedBox(width: 6),
                            Text(
                              phone,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A365D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 14, color: Color(0xFF1A365D)),
                            const SizedBox(width: 6),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A365D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.of(dialogCtx).pop();
                            _isBlockedDialogShowing = false;
                            final uri = Uri.parse('tel:$phone');
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            } catch (_) {}
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Call Support',
                            style: TextStyle(fontSize: 12, color: Color(0xFF2D3748)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogCtx).pop();
                            _isBlockedDialogShowing = false;
                            final patientId = _authCubit?.state.user?.patientId ?? _lastBoundPatientId ?? 'GUEST';
                            _lastBoundPatientId = null;
                            await clearPatientSession(
                              patientId: patientId,
                              careCubit: _careCubit,
                              cartCubit: _cartCubit,
                              appointmentCubit: _appointmentCubit,
                              hairTestCubit: _hairTestCubit,
                            );
                            await _cache.remove('has_completed_hair_test');
                            await _cache.remove('has_skipped_hair_test');
                            await _cache.remove('hair_test_stage');
                            await _authCubit?.signOut();
                            try {
                              AppRouter.router.go(RouteNames.signin);
                            } catch (_) {}
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A365D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      _isBlockedDialogShowing = false;
    }
  }

  @visibleForTesting
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _lastBoundPatientId = null;
  }
}
