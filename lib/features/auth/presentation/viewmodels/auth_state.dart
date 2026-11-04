import '../../domain/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  profileRequired,
  unauthenticated,
  failure,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final int resendCountdown;
  final bool isOtpSent;
  final String? phoneNumber;
  final String? sessionToken;
  final bool isRegistered;
  final bool isAdmin;
  final bool hasCompletedAssessment;
  final String? nextStep;
  final Map<String, dynamic>? latestAssessment;
  final bool requiresPhoneVerification;
  final String? tempToken;
  final String? socialEmail;
  final String? socialName;
  final String? socialProvider;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.resendCountdown = 0,
    this.isOtpSent = false,
    this.phoneNumber,
    this.sessionToken,
    this.isRegistered = false,
    this.isAdmin = false,
    this.hasCompletedAssessment = false,
    this.nextStep,
    this.latestAssessment,
    this.requiresPhoneVerification = false,
    this.tempToken,
    this.socialEmail,
    this.socialName,
    this.socialProvider,
  });

  bool get isAuthenticated {
    if (status == AuthStatus.unauthenticated || status == AuthStatus.initial) {
      return false;
    }
    if (status == AuthStatus.authenticated) {
      return user != null || sessionToken != null;
    }
    if (status == AuthStatus.profileRequired) {
      return sessionToken != null;
    }
    if (status == AuthStatus.loading) {
      return user != null || sessionToken != null;
    }
    return false;
  }

  bool get requiresProfileCompletion => status == AuthStatus.profileRequired;
  bool get isGuest => false;
  bool get canResendOtp => resendCountdown <= 0;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    int? resendCountdown,
    bool? isOtpSent,
    String? phoneNumber,
    String? sessionToken,
    bool? isRegistered,
    bool? isAdmin,
    bool? hasCompletedAssessment,
    String? nextStep,
    Map<String, dynamic>? latestAssessment,
    bool? requiresPhoneVerification,
    String? tempToken,
    String? socialEmail,
    String? socialName,
    String? socialProvider,
    bool clearUser = false,
    bool clearError = false,
    bool clearSession = false,
    bool clearLatestAssessment = false,
    bool clearPhoneVerification = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resendCountdown: resendCountdown ?? this.resendCountdown,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      sessionToken: clearSession ? null : (sessionToken ?? this.sessionToken),
      isRegistered: isRegistered ?? this.isRegistered,
      isAdmin: isAdmin ?? this.isAdmin,
      hasCompletedAssessment:
          hasCompletedAssessment ?? this.hasCompletedAssessment,
      nextStep: nextStep ?? this.nextStep,
      latestAssessment: clearLatestAssessment
          ? null
          : (latestAssessment ?? this.latestAssessment),
      requiresPhoneVerification: clearPhoneVerification
          ? false
          : (requiresPhoneVerification ?? this.requiresPhoneVerification),
      tempToken: clearPhoneVerification ? null : (tempToken ?? this.tempToken),
      socialEmail: clearPhoneVerification ? null : (socialEmail ?? this.socialEmail),
      socialName: clearPhoneVerification ? null : (socialName ?? this.socialName),
      socialProvider:
          clearPhoneVerification ? null : (socialProvider ?? this.socialProvider),
    );
  }
}
