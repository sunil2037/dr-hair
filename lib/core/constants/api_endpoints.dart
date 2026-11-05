import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized API Endpoints registry for the Dr. Hair application.
/// All repositories, data sources, and network clients MUST use endpoints
/// defined in this class rather than hardcoding raw URL strings.
class ApiEndpoints {
  ApiEndpoints._();

  static String get baseUrl => backendBaseUrl;

  /// Returns the configured backend Base URL:
  /// Priority:
  /// 1. dart-define flag (DRHAIR_BACKEND_URL), for explicit build overrides
  /// 2. flutter_dotenv (.env file: DRHAIR_BACKEND_URL or API_BASE_URL)
  /// 3. Live production fallback (https://backend-ten-kappa-69.vercel.app)
  static const String _buildBackendUrl = String.fromEnvironment(
    'DRHAIR_BACKEND_URL',
  );

  static String get backendBaseUrl {
    if (_buildBackendUrl.trim().isNotEmpty) {
      return _buildBackendUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }

    final envUrl = dotenv.isInitialized
        ? (dotenv.env['DRHAIR_BACKEND_URL'] ?? dotenv.env['API_BASE_URL'])
        : null;
    if (envUrl != null && envUrl.trim().isNotEmpty) {
      return envUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://backend-ten-kappa-69.vercel.app';
  }

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  // ---------------------------------------------------------------------------
  // 1. Auth Endpoints (/api/v1/auth)
  // ---------------------------------------------------------------------------
  static const String authSendLoginOtp = '/api/v1/auth/send_login_otp';
  static const String authVerifyLoginOtp = '/api/v1/auth/verify_login_otp';
  static const String authLogin = '/api/v1/auth/login';
  static const String authSendSignupOtp = '/api/v1/auth/send-signup-otp';
  static const String authRegister = '/api/v1/auth/register';
  static const String authSocialLogin = '/api/v1/auth/social-login';
  static const String authVerifySocialSignup = '/api/v1/auth/verify-social-signup';
  static const String authForgotPassword = '/api/v1/auth/forgot-password';
  static const String authResetPassword = '/api/v1/auth/reset-password';
  static const String authSession = '/api/v1/auth/session';
  static const String authRefresh = '/api/v1/auth/refresh';
  static const String authLogout = '/api/v1/auth/logout';

  // ---------------------------------------------------------------------------
  // 2. User & Profile Endpoints (/api/v1/users)
  // ---------------------------------------------------------------------------
  static const String userGetProfile = '/api/v1/users/get_profile';
  static const String userLoginSignup = '/api/v1/users/loginSignup';
  static const String userUpdateProfile = '/api/v1/users/updateProfile';
  static const String userDeleteAccount = '/api/v1/users/deleteAccount';

  // ---------------------------------------------------------------------------
  // 3. Notifications Endpoints (/api/v1/notifications)
  // ---------------------------------------------------------------------------
  static const String notifications = '/api/v1/notifications';
  static String notificationRead(String id) =>
      '/api/v1/notifications/${Uri.encodeComponent(id)}/read';
  static const String notificationsReadAll = '/api/v1/notifications/read-all';
  static const String notificationDeviceTokens =
      '/api/v1/notifications/device-tokens';

  // ---------------------------------------------------------------------------
  // 4. Videos / Reels Endpoints (/api/v1/videos)
  // ---------------------------------------------------------------------------
  static const String videos = '/api/v1/videos';

  // ---------------------------------------------------------------------------
  // 5. Products & Catalog Endpoints (/api/v1/products)
  // ---------------------------------------------------------------------------
  static const String products = '/api/v1/products';
  static const String productCategories = '/api/v1/products/categories';
  static const String categories = '/api/v1/categories';
  static const String videoCategories = '/api/v1/videos/categories';
  static String productById(String id) =>
      '/api/v1/products/${Uri.encodeComponent(id)}';

  // ---------------------------------------------------------------------------
  // 6. Cart Endpoints (/api/v1/cart)
  // ---------------------------------------------------------------------------
  static const String cart = '/api/v1/cart';
  static const String cartItems = '/api/v1/cart/items';
  static String cartItemById(String itemId) =>
      '/api/v1/cart/items/${Uri.encodeComponent(itemId)}';
  static const String cartApplyReward = '/api/v1/cart/apply-reward';
  static const String cartCoupon = '/api/v1/cart/coupon';

  // ---------------------------------------------------------------------------
  // 7. Commerce & Orders Endpoints (/api/v1/commerce, /api/v1/patient)
  // ---------------------------------------------------------------------------
  static const String commerceCheckout = '/api/v1/commerce/checkout';
  static const String commerceVerifyPayment = '/api/v1/commerce/verify-payment';
  static const String patientAddresses = '/api/v1/patient/addresses';
  static String patientAddressById(String id) =>
      '/api/v1/patient/addresses/${Uri.encodeComponent(id)}';
  static const String patientOrders = '/api/v1/patient/orders';
  static String patientOrderById(String orderId) =>
      '/api/v1/patient/orders/${Uri.encodeComponent(orderId)}';
  static String patientOrderCancel(String orderId) =>
      '/api/v1/patient/orders/${Uri.encodeComponent(orderId)}/cancel';

  // ---------------------------------------------------------------------------
  // 8. Content, FAQs & Policies Endpoints (/api/v1/content)
  // ---------------------------------------------------------------------------
  static const String content = '/api/v1/content';
  static const String contentPolicies = '/api/v1/content/policies';
  static String contentPolicyBySlug(String slug) =>
      '/api/v1/content/policies/${Uri.encodeComponent(slug)}';
  static const String contentFaqs = '/api/v1/content/faqs';
  static const String contentStories = '/api/v1/content/stories';
  static const String contentTips = '/api/v1/content/tips';

  // ---------------------------------------------------------------------------
  // 9. Reviews Endpoints (/api/v1/reviews)
  // ---------------------------------------------------------------------------
  static const String reviewsGet = '/api/v1/reviews/review_get';
  static const String reviewsCreate = '/api/v1/reviews/create';

  // ---------------------------------------------------------------------------
  // 10. Hair Test & Assessment Endpoints (/api/v1/hair-tests, /api/v1/patient/assessment)
  // ---------------------------------------------------------------------------
  static const String hairTestSubmitForm = '/api/v1/hair-tests/submit_form';
  static const String patientAssessmentDraft = '/api/v1/patient/assessment/draft';
  static const String patientAssessmentSubmit = '/api/v1/patient/assessment/submit';

  // ---------------------------------------------------------------------------
  // 11. Care, Clinical & Diet Endpoints (/api/v1/patient)
  // ---------------------------------------------------------------------------
  static const String patientClinicalRecord = '/api/v1/patient/clinical-record';
  static const String patientDietPlan = '/api/v1/patient/diet-plan';
  static const String patientRoutineSteps = '/api/v1/patient/routine-steps';
  static String patientRoutineStepByIndex(int index) =>
      '/api/v1/patient/routine-steps/$index';
  static const String patientProgressCheckins =
      '/api/v1/patient/progress-checkins';
  static String patientProgressCheckinById(String checkInId) =>
      '/api/v1/patient/progress-checkins/${Uri.encodeComponent(checkInId)}';
  static String patientReportDownload(String reportId) =>
      '/api/v1/patient/reports/${Uri.encodeComponent(reportId)}/download';

  // ---------------------------------------------------------------------------
  // 12. Clinic Appointments Endpoints (/api/v1/patient/appointments, /api/v1/appointments)
  // ---------------------------------------------------------------------------
  static const String patientAppointments = '/api/v1/patient/appointments';
  static String patientAppointmentById(String appointmentId) =>
      '/api/v1/patient/appointments/${Uri.encodeComponent(appointmentId)}';
  static const String appointmentsClosedDates =
      '/api/v1/appointments/closed-dates';

  // ---------------------------------------------------------------------------
  // 13. Support Endpoints (/api/v1/support)
  // ---------------------------------------------------------------------------
  static const String supportInquiries = '/api/v1/support/inquiries';

  // ---------------------------------------------------------------------------
  // 14. Media Upload Endpoints (/api/v1/media)
  // ---------------------------------------------------------------------------
  static const String mediaUpload = '/api/v1/media/upload';

  // ---------------------------------------------------------------------------
  // 15. App Config & Health Endpoints
  // ---------------------------------------------------------------------------
  static const String appConfig = '/api/v1/app/config';
  static const String appVersion = '/api/v1/app/version';
  static const String health = '/health';

  // Legacy compatibility aliases
  static const String services = '/services';
  static const String doctors = '/doctors';
  static const String profile = '/profile';
}
