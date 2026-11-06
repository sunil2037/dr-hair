import 'package:equatable/equatable.dart';

/// State containing live feature flag availability for the Dr. Hair app.
class AppConfigState extends Equatable {
  final Map<String, bool> features;
  final bool isLoading;
  final String? error;

  const AppConfigState({
    this.features = const <String, bool>{
      'shop': true,
      'clinic_appointment': true,
      'assessment': true,
      'videos': true,
      'reviews': true,
      'routine': true,
      'reminders': true,
      'reports': true,
    },
    this.isLoading = false,
    this.error,
  });

  /// Check whether a specific feature flag is currently active.
  /// Falls back to [defaultValue] (defaults to true) if the flag is missing.
  bool isFeatureEnabled(String key, {bool defaultValue = true}) {
    return features[key] ?? defaultValue;
  }

  AppConfigState copyWith({
    Map<String, bool>? features,
    bool? isLoading,
    String? error,
  }) {
    return AppConfigState(
      features: features ?? this.features,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [features, isLoading, error];
}

