import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/appointments/presentation/clinic_appointment_cubit.dart';
import '../../features/auth/presentation/viewmodels/auth_cubit.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';
import '../../features/care/presentation/viewmodels/care_cubit.dart';
import '../../features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import '../../features/shop/presentation/viewmodels/cart_cubit.dart';
import '../storage/app_local_cache.dart';

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

  /// Attaches listeners to cubits to synchronize patient scope automatically.
  void attach({
    required AuthCubit authCubit,
    required CareCubit careCubit,
    required CartCubit cartCubit,
    required ClinicAppointmentCubit appointmentCubit,
    required HairTestCubit hairTestCubit,
  }) {
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

  @visibleForTesting
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _lastBoundPatientId = null;
  }
}
