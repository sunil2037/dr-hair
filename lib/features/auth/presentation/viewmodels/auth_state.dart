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
  final String? developmentOtp;
  final bool isRegistered;
  final bool isAdmin;
  final bool hasCompletedAssessment;
  final String? nextStep;
  final Map<String, dynamic>? latestAssessment;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.resendCountdown = 0,
    this.isOtpSent = false,
    this.phoneNumber,
    this.sessionToken,
    this.developmentOtp,
    this.isRegistered = false,
    this.isAdmin = false,
    this.hasCompletedAssessment = false,
    this.nextStep,
    this.latestAssessment,
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
    String? developmentOtp,
    bool? isRegistered,
    bool? isAdmin,
    bool? hasCompletedAssessment,
    String? nextStep,
    Map<String, dynamic>? latestAssessment,
    bool clearUser = false,
    bool clearError = false,
    bool clearSession = false,
    bool clearDevelopmentOtp = false,
    bool clearLatestAssessment = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      resendCountdown: resendCountdown ?? this.resendCountdown,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      sessionToken: clearSession ? null : (sessionToken ?? this.sessionToken),
      developmentOtp: clearDevelopmentOtp
          ? null
          : (developmentOtp ?? this.developmentOtp),
      isRegistered: isRegistered ?? this.isRegistered,
      isAdmin: isAdmin ?? this.isAdmin,
      hasCompletedAssessment:
          hasCompletedAssessment ?? this.hasCompletedAssessment,
      nextStep: nextStep ?? this.nextStep,
      latestAssessment: clearLatestAssessment
          ? null
          : (latestAssessment ?? this.latestAssessment),
    );
  }
}
