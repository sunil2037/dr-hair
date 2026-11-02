import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../routes/route_names.dart';
import '../../features/auth/presentation/viewmodels/auth_cubit.dart';
import '../../features/auth/presentation/viewmodels/auth_state.dart';

/// Route guard ensuring protected patient screens require a valid authenticated session.
/// Unauthenticated users are redirected to login with their intended destination preserved.
class AuthRequiredRoute extends StatefulWidget {
  final Widget child;
  final String routePath;

  const AuthRequiredRoute({
    super.key,
    required this.child,
    required this.routePath,
  });

  @override
  State<AuthRequiredRoute> createState() => _AuthRequiredRouteState();
}

class _AuthRequiredRouteState extends State<AuthRequiredRoute> {
  bool _redirectScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuth();
  }

  void _checkAuth() {
    final authState = context.read<AuthCubit?>()?.state;
    if (authState == null) return;

    // Never redirect to sign-in while auth is initializing or in-flight loading
    if (authState.status == AuthStatus.initial ||
        authState.status == AuthStatus.loading) {
      return;
    }

    final isAuthenticated = authState.isAuthenticated;

    if (!isAuthenticated && !_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentAuth = context.read<AuthCubit?>()?.state;
        if (currentAuth == null ||
            currentAuth.status == AuthStatus.initial ||
            currentAuth.status == AuthStatus.loading ||
            currentAuth.isAuthenticated) {
          _redirectScheduled = false;
          return;
        }
        final target = widget.routePath;
        final redirectUri = Uri.encodeComponent(target);
        context.go('${RouteNames.signin}?redirect=$redirectUri');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit?>()?.state;
    if (authState?.isAuthenticated == true ||
        (authState?.status == AuthStatus.loading && authState?.user != null)) {
      return widget.child;
    }
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

