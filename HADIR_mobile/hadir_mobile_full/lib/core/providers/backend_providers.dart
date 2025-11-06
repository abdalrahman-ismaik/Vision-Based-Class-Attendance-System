/// Backend Service Providers
/// 
/// Riverpod providers for backend registration service
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hadir_mobile_full/core/services/backend_registration_service.dart';

/// Provider for backend registration service instance
final backendRegistrationServiceProvider = Provider<BackendRegistrationService>((ref) {
  return BackendRegistrationService();
});

/// Provider to check if backend is available (health check)
/// 
/// Usage:
/// ```dart
/// final backendAvailable = ref.watch(backendAvailabilityProvider);
/// backendAvailable.when(
///   data: (available) => Text(available ? 'Online' : 'Offline'),
///   loading: () => CircularProgressIndicator(),
///   error: (_, __) => Text('Error'),
/// );
/// ```
final backendAvailabilityProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(backendRegistrationServiceProvider);
  return await service.isBackendAvailable();
});
